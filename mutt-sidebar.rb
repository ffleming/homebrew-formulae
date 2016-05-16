# Note: Mutt has a large number of non-upstream patches available for
# it, some of which conflict with each other. These patches are also
# not kept up-to-date when new versions of mutt (occasionally) come
# out.
#
# To reduce Homebrew's maintenance burden, new patches are not being
# accepted for this formula. We would be very happy to see members of
# the mutt community maintain a more comprehesive tap with better
# support for patches.

class MuttSidebar < Formula
  desc "Mongrel of mail user agents (part elm, pine, mush, mh, etc.)"
  homepage "http://www.mutt.org/"
  url "https://bitbucket.org/mutt/mutt/downloads/mutt-1.5.23.tar.gz"
  mirror "ftp://ftp.mutt.org/pub/mutt/mutt-1.5.23.tar.gz"
  sha256 "3af0701e57b9e1880ed3a0dee34498a228939e854a16cdccd24e5e502626fd37"
  version '1.5.23-patched'
  revision 1

  head do
    url "http://dev.mutt.org/hg/mutt#default", :using => :hg

    resource "html" do
      url "http://dev.mutt.org/doc/manual.html", :using => :nounzip
    end
  end

  conflicts_with 'mutt', because: 'mutt-sidebar is mutt, but with some patches'

  unless Tab.for_name("signing-party").with? "rename-pgpring"
    conflicts_with "signing-party",
      :because => "mutt installs a private copy of pgpring"
  end

  conflicts_with "tin",
    :because => "both install mmdf.5 and mbox.5 man pages"

  option "with-debug", "Build with debug option enabled"
  option "with-confirm-attachment-patch", "Apply confirm attachment patch"

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  depends_on "openssl"
  depends_on "tokyo-cabinet"
  depends_on "s-lang"
  depends_on "gpgme" => :optional

  # original source for this went missing, patch sourced from Arch at
  # https://aur.archlinux.org/packages/mutt-ignore-thread/
  if build.with? "confirm-attachment-patch"
    patch do
      url "https://gist.githubusercontent.com/tlvince/5741641/raw/c926ca307dc97727c2bd88a84dcb0d7ac3bb4bf5/mutt-attach.patch"
      sha256 "da2c9e54a5426019b84837faef18cc51e174108f07dc7ec15968ca732880cb14"
    end
  end

  patch do
    url "https://raw.github.com/nedos/mutt-sidebar-patch/7ba0d8db829fe54c4940a7471ac2ebc2283ecb15/mutt-sidebar.patch"
    sha256 "de592f9eeae458cac8de15a22230b3b426da71a62369617030a84787ccb08712"
  end

  patch do
    url "http://ftp.openbsd.org/pub/OpenBSD/distfiles/mutt/trashfolder-1.5.22.diff0.gz"
    sha256 "ce964144264a7d4f121e7a2692b1ea92ebea5f03089bfff6961d485f3339c3b8"
  end

  def install
    args = ["--disable-dependency-tracking",
            "--disable-warnings",
            "--prefix=#{prefix}",
            "--with-ssl=#{Formula["openssl"].opt_prefix}",
            "--with-sasl",
            "--with-gss",
            "--enable-imap",
            "--enable-smtp",
            "--enable-pop",
            "--enable-hcache",
            "--with-tokyocabinet",
            # This is just a trick to keep 'make install' from trying
            # to chgrp the mutt_dotlock file (which we can't do if
            # we're running as an unprivileged user)
            "--with-homespool=.mbox",
            "--with-slang"]
    args << "--enable-gpgme" if build.with? "gpgme"

    if build.with? "debug"
      args << "--enable-debug"
    else
      args << "--disable-debug"
    end

    system "./prepare", *args
    system "make"
    system "make", "install"

    doc.install resource("html") if build.head?
  end

  test do
    system bin/"mutt", "-D"
  end
end
