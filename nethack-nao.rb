require "etc"

# Nethack the way God intended it to be played: from a terminal.
# This build script was created referencing:
# * http://nethackwiki.com/wiki/Compiling#On_Mac_OS_X
# * http://nethackwiki.com/wiki/Pkgsrc#patch-ac_.28system.h.29
# and copious hacking until things compiled.
#
# The patch applied incorporates the patch-ac above, the OS X
# instructions from the Wiki, and whatever else needed to be
# done.
# - @adamv

# In addition to @adamv's changes, which were used as the
# basis for OSX functionality, the supplied patch incorporates
# several usability patches using nethack.alt.org as a
# guide.  This includes statuscolors, menucolors, sortloot,
# and more.  For more information, see
#     https://github.com/ffleming/nethack-3.4.3-nao-osx
# - @ffleming

class NethackNao < Formula
  desc "Single-player roguelike video game"
  homepage 'http://www.nethack.org/index.html'
  url 'https://downloads.sourceforge.net/project/nethack/nethack/3.4.3/nethack-343-src.tgz'
  version '3.4.3-nao'
  revision 1
  sha256 'bb39c3d2a9ee2df4a0c8fdde708fbc63740853a7608d2f4c560b488124866fe4'

  fails_with :llvm do
    build 2334
  end

  conflicts_with 'nethack', because: 'nethack-nao *is* nethack, but with some patches'
  patch do
    url 'https://raw.githubusercontent.com/ffleming/nethack-3.4.3-nao-osx/v1.2/nethack-3.4.3-nao-osx.diff'
    sha256 'b2b37cc8c41d4949b12b5cfde6b51108f4c5b890530d34b454a61808d1d55166'
  end

  def user
    Etc.getpwuid.name
  end

  def gamedir
    libexec
  end

  def vardir
    var + 'nethack'
  end

  def savedir
    vardir + 'save'
  end

  def caveats
    <<-EOS.undent
    nao-osx (v3.4.3-nao) is incompatible with vanilla (v3.4.3) nethack saves
    Old saves can be found in #{HOMEBREW_PREFIX}/Cellar/#{name}/3.4.3/libexec/save
    EOS
  end

  def install
    # Build everything in-order; no multi builds.
    ENV.deparallelize

    # Use the user, not 'wizard', for wizard mode.  Ensures that the "Contact WIZARD_NAME" debug
    # message provides useful information.
    inreplace "include/config.h" do |s|
      s.gsub!(/^#\s*define\s+WIZARD\s+"wizard".*$/, "#define WIZARD \"#{user}\"")
      s.gsub!(/^#\s*define\s+WIZARD_NAME.*$/, "#define WIZARD_NAME \"#{user}\"")
    end

    # Patch the patch!  The patch installs to /opt and assumes a non-Homebrew system. This
    # sets the insall location to the appropriate cellar.
    inreplace "include/config.h",
      /^#\s*define\s+HACKDIR.*$/, "#define HACKDIR \"#{gamedir}\""

    inreplace "include/unixconf.h",
      /^#define\s+VAR_PLAYGROUND.*$/, "#define VAR_PLAYGROUND \"#{vardir}\""

    inreplace "sys/unix/Makefile.top" do |s|
      s.gsub!(/^PREFIX\s*=.*$/,"PREFIX = #{prefix}")
      s.gsub!(/^GAMEDIR\s*=.*$/,"GAMEDIR = #{gamedir}")
      s.gsub!(/^VARDIR\s*=.*$/,"VARDIR = #{vardir}")
      s.gsub!(/^GAMEUID\s*=.*$/,"GAMEUID = #{user}")
    end

    inreplace "sys/unix/Makefile.doc",
      /^MANDIR\s*=.*$/, "MANDIR = #{man6}"

    # Copy makefiles
    system 'sh', 'sys/unix/setup.sh'

    # Build and install
    system 'make'
    system 'make', 'install'

    # Create manpage path and install manpages
    man6.mkpath
    cd 'doc' do
      system 'make', 'manpages'
    end

    # Install nethack binary (recover binary is in gamedir)
    bin.install 'src/nethack'

    # These need to be group-writable in multi-user situations
    savedir.mkpath
    gamedir.chmod(0775)
    savedir.chmod(0775)
  end

  def post_install
    # Copy save files from the vanilla nethack save directory. Will not overwrite.
    if Dir.exists? "#{HOMEBREW_PREFIX}/Cellar/#{name}/3.4.3/libexec/save"
      cp_r "#{HOMEBREW_PREFIX}/Cellar/#{name}/3.4.3/libexec/save/.", savedir
    end
  end

  test do
    system bin/'nethack', '--version'
  end
end
