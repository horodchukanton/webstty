package Abills::Base;

=head1 NAME

Abills::Base - Base functions

=head1 SYNOPSIS

    use Abills::Base;

    convert();

=cut

no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use feature 'state';
use strict;
our (@EXPORT_OK, %EXPORT_TAGS);

use POSIX qw(locale_h strftime mktime);
use parent 'Exporter';

our $VERSION = 2.00;

our @EXPORT = qw(
  null
  convert
  int2ip
  ip2int
  int2byte
  int2ml
  sec2date
  sec2time
  time2sec
  decode_base64
  encode_base64
  urlencode
  urldecode
  date_diff
  date_format
  parse_arguments
  mk_unique_value
  check_time
  gen_time
  sendmail
  in_array
  tpl_parse
  cfg2hash
  clearquotes
  cmd
  ssh_cmd
  _bp
  startup_files
  show_log
  days_in_month
  next_month
  show_hash
  load_pmodule2
  date_inc
);

@EXPORT_OK = qw(
  null
  convert
  int2ip
  ip2int
  int2byte
  int2ml
  sec2date
  sec2time
  time2sec
  decode_base64
  encode_base64
  urlencode
  urldecode
  date_diff
  date_format
  parse_arguments
  mk_unique_value
  check_time
  gen_time
  sendmail
  in_array
  tpl_parse
  cfg2hash
  clearquotes
  cmd
  ssh_cmd
  _bp
  startup_files
  show_log
  days_in_month
  next_month
  show_hash
  load_pmodule2
);

# As said in perldoc, should be called once on a program
srand();

#**********************************************************
=head2 null() Null function

  Return:
    true

=cut
#**********************************************************
sub null {

  return 1;
}

#**********************************************************
=head2 cfg2hash($cfg, $attr) Convert cft str to hash

  Arguments:
    $cfg
      format:
        key:value;key:value;key:value;
    $attr

  Results:

=cut
#**********************************************************
sub cfg2hash {
  my ($cfg) = @_;
  my %hush = ();

  return \%hush if (!$cfg);

  $cfg =~ s/\n//g;
  my @cfg_options = split(/;/, $cfg);

  foreach my $line (@cfg_options) {
    my ($k, $v) = split(/:/, $line, 2);
    $k =~ s/^\s+//;
    $hush{$k} = $v;
  }

  return \%hush;
}

#**********************************************************
=head2 in_array($value, $array) - Check value in array

  Arguments:

    $value   - Search value
    $array   - Array ref

  Returns:

    true or false

  Examples:

    my $ret = in_array(10, \@array);

=cut
#**********************************************************
sub in_array {
  my ($value, $array) = @_;

  return 0 if (!defined($value));

  if ( $] <= 5.010 ) {
    if (grep { $_ eq $value } @$array) {
      return 1;
    }
  }
  else {
    if ($value ~~ @$array) {
      return 1;
    }
  }

  return 0;
}

#**********************************************************
=head2 convert($text, $attr) - Converter text

   Attributes:
     $text     - Text for convertation
     $attr     - Params
       text2html - convert text to HTML
       html2text -
       txt2translit - text to translit
       json      - Convert \n to \\n

       Transpation
         win2koi
         koi2win
         win2iso
         iso2win
         win2dos
         dos2win

  Returns:

    converted text

  Examples:
     convert($text, $attr)

  Formating text

    convert($text, { text2html => 1, SHOW_URL => 1 });

=cut
#**********************************************************
sub convert {
  my ($text, $attr) = @_;

  # $str =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
  if (defined($attr->{text2html})) {
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/\"/&quot;/g;
    $text =~ s/\n/<br\/>\n/gi if (! $attr->{json});
    $text =~ s/[\r\n]/\n/gi if ($attr->{json});
    $text =~ s/\%/\&#37/g;
    $text =~ s/\*/&#42;/g;
    #$text =~ s/\+/\%2B/g;

    if ($attr->{SHOW_URL}) {
      $text =~ s/([https|http]+:\/\/[a-z\.0-9\/\?\&\-\_\#:\=]+)/<a href=\'$1\' target=_new>$1<\/a>/ig;
    }
  }
  elsif (defined($attr->{html2text})) {
  	$text =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
  }
  elsif (defined($attr->{txt2translit})) {
  	$text = txt2translit($text);
  }
  elsif ($attr->{'from_tpl'}) {
    $text =~ s/textarea/__textarea__/g;
  }
  elsif ($attr->{'2_tpl'}) {
    $text =~ s/__textarea__/textarea/g;
  }
  elsif ($attr->{win2utf8}) { $text = win2utf8($text);}
  elsif ($attr->{utf82win}) { $text = utf82win($text);}
  elsif ($attr->{win2koi})  { $text = win2koi($text); }
  elsif ($attr->{koi2win})  { $text = koi2win($text); }
  elsif ($attr->{win2iso})  { $text = win2iso($text); }
  elsif ($attr->{iso2win})  { $text = iso2win($text); }
  elsif ($attr->{win2dos})  { $text = win2dos($text); }
  elsif ($attr->{dos2win})  { $text = dos2win($text); }
  elsif ($attr->{cp8662utf8}) { $text = cp8662utf8($text); }
  elsif ($attr->{utf82cp866}) { $text = utf82cp866($text); }

  if($attr->{json}) {
    $text =~ s/\n/\\n/g;
  }

  return $text;
}

sub win2koi {
  my $pvdcoderwin = shift;
  $pvdcoderwin =~
tr/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/\xE1\xE2\xF7\xE7\xE4\xE5\xF6\xFA\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF2\xF3\xF4\xF5\xE6\xE8\xE3\xFE\xFB\xFD\xFF\xF9\xF8\xFC\xE0\xF1\xC1\xC2\xD7\xC7\xC4\xC5\xD6\xDA\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD2\xD3\xD4\xD5\xC6\xC8\xC3\xDE\xDB\xDD\xDF\xD9\xD8\xDC\xC0\xD1/;
  return $pvdcoderwin;
}

sub koi2win {
  my $pvdcoderwin = shift;
  $pvdcoderwin =~
tr/\xE1\xE2\xF7\xE7\xE4\xE5\xF6\xFA\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF2\xF3\xF4\xF5\xE6\xE8\xE3\xFE\xFB\xFD\xFF\xF9\xF8\xFC\xE0\xF1\xC1\xC2\xD7\xC7\xC4\xC5\xD6\xDA\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD2\xD3\xD4\xD5\xC6\xC8\xC3\xDE\xDB\xDD\xDF\xD9\xD8\xDC\xC0\xD1\xA6/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF\xB3/;
  return $pvdcoderwin;
}

sub win2iso {
  my $pvdcoderiso = shift;
  $pvdcoderiso =~
tr/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/;
  return $pvdcoderiso;
}

sub iso2win {
  my $pvdcoderiso = shift;
  $pvdcoderiso =~
tr/\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/;
  return $pvdcoderiso;
}

sub win2dos {
  my $pvdcoderdos = shift;
  $pvdcoderdos =~
tr/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/;
  return $pvdcoderdos;
}

sub dos2win {
  my $pvdcoderdos = shift;
  $pvdcoderdos =~
tr/\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/;
  return $pvdcoderdos;
}

#**********************************************************
=head2 txt2translit($text) - convert to translit

=cut
#**********************************************************
sub txt2translit {
  my $text = shift;

  $text =~ y/����������������������������/abvgdeezijklmnoprstufh'y'eiei/;
  $text =~ y/�����Ũ������������������ݲ��/ABVGDEEZIJKLMNOPRSTUFH'Y'EIEI/;

  my %mchars = (
    '�' => 'zh',
    '�' => 'ts',
    '�' => 'ch',
    '�' => 'sh',
    '�' => 'sch',
    '�' => 'ju',
    '�' => 'ja',
    '�' => 'Zh',
    '�' => 'Ts',
    '�' => 'Ch',
    '�' => 'Sh',
    '�' => 'Sch',
    '�' => 'Ju',
    '�' => 'Ja'
  );

  for my $c (keys %mchars) {
    $text =~ s/$c/$mchars{$c}/g;
  }

  return $text;
}

#**********************************************************
=head2 win2utf8($text)

  http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1251.TXT

=cut
#**********************************************************
sub win2utf8 {
  my ($text, $attr) = @_;

  my $Unicode = '';

  if ($attr->{OLD}) {
    my @ChArray = split('', $text);
    my $Code    = '';
    for (@ChArray) {
      $Code = ord;

      #return $Code;
      if (($Code >= 0xc0) && ($Code <= 0xff)) { $Unicode .= "&#" . (0x350 + $Code) . ";"; }
      elsif ($Code == 0xa8) { $Unicode .= "&#" . (0x401) . ";"; }
      elsif ($Code == 0xb8) { $Unicode .= "&#" . (0x451) . ";"; }
      elsif ($Code == 0xb3) { $Unicode .= "&#" . (0x456) . ";"; }
      elsif ($Code == 0xaa) { $Unicode .= "&#" . (0x404) . ";"; }
      elsif ($Code == 0xba) { $Unicode .= "&#" . (0x454) . ";"; }
      elsif ($Code == 0xb2) { $Unicode .= "&#" . (0x406) . ";"; }
      elsif ($Code == 0xaf) { $Unicode .= "&#" . (0x407) . ";"; }
      elsif ($Code == 0xbf) { $Unicode .= "&#" . (0x457) . ";"; }
      else                  { $Unicode .= $_; }
    }
  }
  else {
    require Encode;
    Encode->import();
    $Unicode = Encode::encode('utf8', Encode::decode('cp1251', $text));
  }

  return $Unicode;
}

#**********************************************************
=head2 utf82win($text)

   http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1251.TXT
   http://www.utf8-chartable.de/unicode-utf8-table.pl

=cut
#**********************************************************
sub utf82win {
  my ($text) = @_;

  require Encode;
  Encode->import();
  my $win1251 = Encode::encode('cp1251', Encode::decode('utf8', $text));

  return $win1251;
}

#**********************************************************
=head2 cp8662utf8($text)

  Arguments:


  Returns:

=cut
#**********************************************************
sub cp8662utf8 {
  my ($text) = @_;

  require Encode;
  Encode->import();

  my $utf8 = Encode::encode('utf-8', Encode::decode('cp866', $text));
  return $utf8;
}

#**********************************************************
=head2 utf82cp866($text)

  Arguments:


  Returns:

=cut
#**********************************************************
sub utf82cp866 {
  my ($text) = @_;

  require Encode;
  Encode->import();

  my $cp866 = Encode::encode('cp866', Encode::decode('utf-8', $text));
  return $cp866;
}

#**********************************************************
=head2 parse_arguments(\@ARGV, $attr) - Parse comand line arguments

  Arguments:

    @ARGV   - Command line arguments

  Returns:

    return HASH_REF of values

  Examples:

    my $argv = parse_arguments(\@ARGV);

=cut
#**********************************************************
sub parse_arguments {
  my ($argv, $attr) = @_;

  my %args = ();

  foreach my $line (@$argv) {
    if ($line =~ /=/) {
      my ($k, $v) = split(/=/, $line, 2);
      $args{"$k"} = (defined($v)) ? $v : '';
    }
    else {
      $args{"$line"} = 1;
    }
  }

  if($attr) {
    foreach my $param ( keys %$attr ) {
      if($args{$param}) {
        my $fn = $attr->{$param};
        &{ \&$fn }();
      }
    }
  }

  return \%args;
}

#***********************************************************
=head2 sendmail($from, $to_addresses, $subject, $message, $charset, $priority, $attr) - Send mail message

  Arguments:

    $from          - Sender e-mail
    $to_addresses  - Receipt e-mail
    $subject       - Subject
    $message       - Message
    $charset       - Charset
    $priority      - Priority

    $attr          - Attributes
      ATTACHMENTS    - ARRAY of attachments
      SENDMAIL_PATH  - path to sendmail program (Default: /usr/sbin/sendmail)
      MAIL_HEADER    - Custom mail header
      TEST           - Test mode. Only show email body
      CONTENT_TYPE   - Content Type
      ACTIONS        - Make actions fields
      ID             - Message ID

  Returns:
    0 - true
    1 - error
    2 - reciever email not specified

  Examples:

    sendmail("$conf{ADMIN_MAIL}", "user@email", "Subject", "Message text",
          "$conf{MAIL_CHARSET}", "2 (High)");

=cut
#***********************************************************
sub sendmail {
  my ($from, $to_addresses, $subject, $message, $charset, $priority, $attr) = @_;
  if ($to_addresses eq '') {
    return 2;
  }
  my $SENDMAIL = (defined($attr->{SENDMAIL_PATH})) ? $attr->{SENDMAIL_PATH} : '/usr/sbin/sendmail';

  $charset //= 'utf-8';

  if (!-f $SENDMAIL) {
    print "Mail delivery agent not exists";
    return 0;
  }

  if (! $from) {
    return 0;
  }

  my $header = '';
  if ($attr->{MAIL_HEADER}) {
    foreach my $line (@{ $attr->{MAIL_HEADER} }) {
      $header .= "$line\n";
    }
  }

  my $ext_header = '';
  $message =~ s/#.+//g;
  if ($message =~ s/Subject: (.+)[\n\r]+//g) {
    $subject = $1;
  }
  if ($message =~ s/From: (.+)[\n\r]+//g) {
    $from = $1;
  }
  if ($message =~ s/X-Priority: (.+)[\n\r]+//g) {
    $priority = $1;
  }
  if ($message =~ s/To: (.+)[\r\n]+//gi) {
    $to_addresses = $1;
  }

  if ($message =~ s/Bcc: (.+)[\r\n]+//gi) {
    $ext_header = "Bcc: $1\n";
  }

  $to_addresses =~ s/[\n\r]//g;

  if ($attr->{ACTIONS}) {
    push @{ $attr->{ATTACHMENTS} }, {
#       CONTENT =>  qq{
#<div itemscope itemtype="http://schema.org/EmailMessage">
#<div itemprop="potentialAction" itemscope itemtype="http://schema.org/SaveAction">
#    <meta itemprop="name" content="Reply"/>
#    <div itemprop="handler" itemscope itemtype="http://schema.org/HttpActionHandler">
#      <link itemprop="url" href="$attr->{ACTIONS}"/>
#    </div>
#  </div>
#  <meta itemprop="description" content="Reply"/>
#</div>
#},
      CONTENT      => qq{
        <div itemscope itemtype="http://schema.org/EmailMessage">
  <div itemprop="potentialAction" itemscope itemtype="http://schema.org/ViewAction">
    <link itemprop="target" href="$attr->{ACTIONS}"/>
    <meta itemprop="name" content="Watch message"/>
  </div>
  <meta itemprop="description" content="Watch support message"/>
</div>
      },
      CONTENT_TYPE => 'text/html'
    }
  }

  if ($attr->{ATTACHMENTS}) {
    my $boundary = "----------581DA1EE12D00AAA";
    $header .= "MIME-Version: 1.0
Content-Type: multipart/mixed;\n boundary=\"$boundary\"\n";

    $message = qq{--$boundary
Content-Type: text/plain; charset=$charset
Content-Transfer-Encoding: quoted-printable

$message};

    foreach my $attachment (@{ $attr->{ATTACHMENTS} }) {
      my $data = $attachment->{CONTENT};
      $message .= "\n--$boundary\n";

      if($ENV{SENDMAIL_SAVE_ATTACH}) {
        open(my $fh, '>', '/tmp/'.$attachment->{FILENAME});
          print $fh $attachment->{CONTENT};
        close $fh;
      }

      $message .= "Content-Type: $attachment->{CONTENT_TYPE};\n";
      $message .= " name=\"$attachment->{FILENAME}\"\n" if ($attachment->{FILENAME});
      if ($attachment->{CONTENT_TYPE} ne 'text/html') {
        $data = encode_base64($attachment->{CONTENT});
        $message .= "Content-transfer-encoding: base64\n";
      }
      $message .= "Content-Disposition: attachment;\n filename=\"$attachment->{FILENAME}\"\n" if ($attachment->{FILENAME});
      $message .= "\n";
      $message .= qq{$data};
      $message .= "\n";
    }

    $message .= "--$boundary" . "--\n\n";
  }

  if ($attr->{TEST})   {
    print "Test mode enable: $attr->{TEST}\n";
  }

  my @emails_arr = split(/;/, $to_addresses);
  foreach my $to (@emails_arr) {
    if ($attr->{TEST}) {
      print "To: $to\n";
      print "From: $from\n";
      print $ext_header;
      print "Content-Type: text/plain; charset=$charset\n";
      print "X-Priority: $priority\n" if ($priority);
      print $header;
      print "Subject: $subject\n\n";
      print "$message";
    }
    else {
      open(my $mail, '|-', "$SENDMAIL -t") || die "Can't open file '$SENDMAIL' $!\n";
        print $mail "To: $to\n";
        print $mail "From: $from\n";
        print $mail $ext_header;
        print $mail "Content-Type: ". (($attr->{CONTENT_TYPE}) ? $attr->{CONTENT_TYPE} : 'text/plain') ."; charset=$charset\n" if (!$attr->{ATTACHMENTS});
        print $mail "X-Priority: $priority\n" if ($priority);
        print $mail "X-Mailer: ABillS\n";
        print $mail "X-ABILLS_ID: $attr->{ID}\n" if ($attr->{ID});
        print $mail $header;
        print $mail "Subject: $subject \n\n";
        print $mail "$message";

      close($mail);
    }
  }

  return 1;
}

#**********************************************************
=head2 show_log($uid, $type, $attr) - Log parser

  Attributes:
    $uid
    $type
    $attr
      PAGE_ROWS
      PG
      DATE
      LOG_TYPE

=cut
#**********************************************************
sub show_log {
  my ($login, $logfile, $attr) = @_;

  my @err_recs = ();
  my %types    = ();

  my $PAGE_ROWS = ($attr->{PAGE_ROWS})   ? $attr->{PAGE_ROWS} : 25;
  my $PG        = (defined($attr->{PG})) ? $attr->{PG}        : 1;

  $login =~ s/\*/\[\.\]\{0,100\}/g if ($login ne '');

  open(my $fh, '<', $logfile) || die "Can't open log file '$logfile' $!\n";
  my ($date, $time, $log_type, $action, $user, $message);
  while (<$fh>) {
    if (/(\d+\-\d+\-\d+) (\d+:\d+:\d+) ([A-Z_]+:) ([A-Z_]+) \[(.+)\] (.+)/) {
      $date     = $1;
      $time     = $2;
      $log_type = $3;
      $action   = $4;
      $user     = $5;
      $message  = $6;
    }
    else {
      next;
    }

    if (defined($attr->{LOG_TYPE}) && "$log_type" ne "$attr->{LOG_TYPE}:") {
      next;
    }

    if (defined($attr->{DATE}) && $date ne $attr->{DATE}) {
      next;
    }

    if ($login ne "") {
      if ($user =~ /^[ ]{0,1}$login\s{0,1}$/i) {
        push @err_recs, $_;
        $types{$log_type}++;
      }
    }
    else {
      push @err_recs, $_;
      $types{$log_type}++;
    }
  }
  close($fh);

  my $total = $#err_recs;
  my @list;

  return (\@list, \%types, $total) if ($total < 0);
  for (my $i = $total - $PG ; $i >= ($total - $PG) - $PAGE_ROWS && $i >= 0 ; $i--) {
    push @list, "$err_recs[$i]";
  }

  $total++;
  return (\@list, \%types, $total);
}

#**********************************************************
=head2 mk_unique_value($size, $attr) - Make unique value

  Arguments:
    $size  - Size of result string
    $attr
      SYMBOLS     -
      EXTRA_RULES - '$chars:$case' (0 - num, 1 - special, 2 - both):(0 - lower, 1 - upper, 2 - both)

  Results:
    $value - Uniques string

=cut
#**********************************************************
sub mk_unique_value {
  my ($size, $attr) = @_;
  my $symbols = (defined($attr->{SYMBOLS})) ? $attr->{SYMBOLS} : "qwertyupasdfghjikzxcvbnmQWERTYUPASDFGHJKLZXCVBNM123456789";

  my @check_rules = ();
  if ( $attr->{EXTRA_RULES} ){
    my ($chars, $case) = split(':', $attr->{EXTRA_RULES}, 2);

    my $uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    my $lowercase = "abcdefghijklmnopqrstuvwxyz";

    my $numbers = "0123456789";
    my $special = "-_!&%@#:";

    $chars //= 0; # numeric
    $case //= 0;  # lowercase

    my $symbols_ = $numbers;
    if ($chars == 1) {        # Special
      $symbols_ = $special;
      push (@check_rules, $symbols_);
    }
    elsif ($chars == 2) {     # Both
      $symbols_ .= $special;
      push (@check_rules, $numbers, $special);
    }
    elsif ($chars == 3) {     # None of special
      $symbols_ = '';
    }
    else {                    # Numbers only
      push (@check_rules, $numbers);
    }
    
    my $literals = $lowercase;
    if ($case == 1) {         # Uppercase
      $literals = $uppercase;
      push (@check_rules, $uppercase)
    }
    elsif ($case == 2) {         # Both
      $literals .= $uppercase;
      push (@check_rules, $lowercase, $uppercase)
    }
    else {                    # Lowercase only
      push (@check_rules, $lowercase);
    }

    $symbols = $symbols_ . $literals;
  }

  my $value  = '';
  my $random = '';
  $size = 6 if (int($size) < 1);
  my $rand_values = length($symbols);
  for (my $i = 0 ; $i < $size ; $i++) {
    $random = int(rand($rand_values));
    $value .= substr($symbols, $random, 1);
  }
  
  foreach my $rule (@check_rules){
    if ($rule && $value !~ /[$rule]+/ ) {
      $value = &mk_unique_value;
    }
  }

  return $value;
}

#**********************************************************
=head2 int2ip($int) Convert integer value to ip

=cut
#**********************************************************
sub int2ip {
  my $int = shift;

  my $w=($int/16777216)%256;
  my $x=($int/65536)%256;
  my $y=($int/256)%256;
  my $z=$int%256;
  return "$w.$x.$y.$z";

  #Old way
#  my @d = ();
#  $d[0] = int($int / 256 / 256 / 256);
#  $d[1] = int(($int - $d[0] * 256 * 256 * 256) / 256 / 256);
#  $d[2] = int(($int - $d[0] * 256 * 256 * 256 - $d[1] * 256 * 256) / 256);
#  $d[3] = int($int - $d[0] * 256 * 256 * 256 - $d[1] * 256 * 256 - $d[2] * 256);
#return "$d[0].$d[1].$d[2].$d[3]";
}

#**********************************************************
=head2 ip2int($ip) - Convert ip to int

=cut
#**********************************************************
sub ip2int {
  my $ip = shift;

  return unpack("N", pack("C4", split(/\./, $ip)));
}

#***********************************************************
=head2 time2sec($time, $attr) - Time to second

  Returns:
    $sec;

=cut
#***********************************************************
sub time2sec {
  my ($time) = @_;

  my ($H, $M, $S) = split(/:/, $time, 3);

  my $sec = ($H * 60 * 60) + ($M * 60) + $S;

  return $sec;
}

#**********************************************************
=head2 sec2time($value, $attr) - Seconds to date format

  Convert seconds to date format

  Arguments:
    $value - number, seconds for conversion
    $attr
      format - return in 'HH:MM:SS' format
      str    - return in '+D HH:MM:SS' format

  Returns:
    array - ($seconds, $minutes, $hours, $days)
    if $attr see 'Arguments'

  Examples:
    

=cut
#**********************************************************
sub sec2time {
  my ($value, $attr) = @_;
  my ($seconds, $minutes, $hours, $days);

  $seconds = int($value % 60);
  $minutes = int(($value % 3600) / 60);
  $hours = int(($value % (24 * 3600)) / 3600);
  $days = int($value / (24 * 3600));

  if ($attr->{format}) {
    $hours = int($value / 3600);
    return sprintf("%.2d:%.2d:%.2d", $hours, $minutes, $seconds);
  }
  elsif ($attr->{str}) {
    return sprintf("+%d %.2d:%.2d:%.2d", $days, $hours, $minutes, $seconds);
  }
  else {
    return ($seconds, $minutes, $hours, $days);
  }
}

#***********************************************************
=head2 sec2date($secnum) - Convert second to date

  Arguments:
    $secnum - Unixtime

  Returns:
    "$year-$mon-$mday $hour:$min:$sec"

=cut
#***********************************************************
sub sec2date {
  my ($secnum) = @_;

  return "0000-00-00 00:00:00" if ($secnum == 0);

  my ($sec, $min, $hour, $mday, $mon, $year, undef, undef, undef) = localtime($secnum);
  $year += 1900;
  $mon++;
  $sec  = sprintf("%02d", $sec);
  $min  = sprintf("%02d", $min);
  $hour = sprintf("%02d", $hour);
  $mon  = sprintf("%02d", $mon);
  $mday = sprintf("%02d", $mday);

  return "$year-$mon-$mday $hour:$min:$sec";
}

#***********************************************************
=head2 int2byte($val, $attr) - Convert Integer to byte definision

  $KBYTE_SIZE - Size of kilobyte (Standart 1024)

=cut
#***********************************************************
sub int2byte {
  my ($val, $attr) = @_;

  my $KBYTE_SIZE = 1024;
  $KBYTE_SIZE = int($attr->{KBYTE_SIZE}) if (defined($attr->{KBYTE_SIZE}));
  my $MEGABYTE = $KBYTE_SIZE * $KBYTE_SIZE;
  my $GIGABYTE = $KBYTE_SIZE * $KBYTE_SIZE * $KBYTE_SIZE;
  $val = int($val);

  if ($attr->{DIMENSION}) {
    if ($attr->{DIMENSION} eq 'Mb') {
      $val = sprintf("%.2f MB", $val / $MEGABYTE);
    }
    elsif ($attr->{DIMENSION} eq 'Gb') {
      $val = sprintf("%.2f GB", $val / $GIGABYTE);
    }
    elsif ($attr->{DIMENSION} eq 'Kb') {
      $val = sprintf("%.2f Kb", $val / $KBYTE_SIZE);
    }
    else {
      $val .= " Bt";
    }
  }
  elsif ($val > $GIGABYTE)   { $val = sprintf("%.2f GB", $val / $GIGABYTE); }     # 1024 * 1024 * 1024
  elsif ($val > $MEGABYTE)   { $val = sprintf("%.2f MB", $val / $MEGABYTE); }     # 1024 * 1024
  elsif ($val > $KBYTE_SIZE) { $val = sprintf("%.2f Kb", $val / $KBYTE_SIZE); }
  else                       { $val .= " Bt"; }

  return $val;
}

#***********************************************************
=head2 int2ml($sum, $attr) integet to money in litteral format

  Arguments:
    $sum
    $attr

  Returns:
    $literal_sum

=cut
#***********************************************************
sub int2ml {
  my ($array, $attr) = @_;
  my $ret = '';

  my @ones  = @{ $attr->{ONES} };
  my @twos  = @{ $attr->{TWOS} };
  my @fifth = @{ $attr->{FIFTH} };

  my @one     = @{ $attr->{ONE} };
  my @onest   = @{ $attr->{ONEST} };
  my @ten     = @{ $attr->{TEN} };
  my @tens    = @{ $attr->{TENS} };
  my @hundred = @{ $attr->{HUNDRED} };

  my @money_unit_names = ();

  if($attr->{MONEY_UNIT_NAMES}) {
    if (ref $attr->{MONEY_UNIT_NAMES} ne 'ARRAY') {
      @money_unit_names = split(/;/, $attr->{MONEY_UNIT_NAMES});
    }
    else {
      @money_unit_names = @{ $attr->{MONEY_UNIT_NAMES} };
    }
  }
  $array =~ s/,/\./g;
  $array =~ tr/0-9,.//cd;
  my $tmp = $array;
  my $count = ($tmp =~ tr/.,//);

  if ($count > 1) {
    $ret .= "bad integer format\n";
    return 1;
  }

  my $second = "00";
  my ($first, @first, $i);

  if (!$count) {
    $first = $array;
  }
  else {
    $first = $second = $array;
    $first  =~ s/(.*)(\..*)/$1/;
    $second =~ s/(.*)(\.)(\d\d)(.*)/$3/;
    $second .= "0" if (length $second < 2);
  }

  $count = int((length $first) / 3);
  my $first_length = length $first;

  for ($i = 1 ; $i <= $count ; $i++) {
    $tmp = $first;
    $tmp   =~ s/(.*)(\d\d\d$)/$2/;
    $first =~ s/(.*)(\d\d\d$)/$1/;
    $first[$i] = $tmp;
  }

  if ($count < 4 && $count * 3 < $first_length) {
    $first[$i] = $first;
    $first_length = $i;
  }
  else {
    $first_length = $i - 1;
  }

  for ($i = $first_length ; $i >= 1 ; $i--) {
    $tmp = 0;
    for (my $j = length($first[$i]) ; $j >= 1 ; $j--) {
      if ($j == 3) {
        $tmp = $first[$i];
        $tmp =~ s/(^\d)(\d)(\d$)/$1/;
        $ret .= $hundred[$tmp];

        if ($tmp > 0) {
          $ret .= " ";
        }
      }
      if ($j == 2) {
        $tmp = $first[$i];
        $tmp =~ s/(.*)(\d)(\d$)/$2/;
        if ($tmp != 1) {
          $ret .= $ten[$tmp];
          if ($tmp > 0) {
            $ret .= " ";
          }
        }
      }
      if ($j == 1) {
        if ($tmp != 1) {
          $tmp = $first[$i];
          $tmp =~ s/(.*)(\d$)/$2/;
          if ((($i == 1) || ($i == 2)) && ($tmp == 1 || $tmp == 2)) {
            $ret .= $onest[$tmp];
            if ($tmp > 0) {
              $ret .= " ";
            }
          }
          else {
            $ret .= $one[$tmp];
            if ($tmp > 0) {
              $ret .= " ";
            }
          }
        }
        else {
          $tmp = $first[$i];
          $tmp =~ s/(.*)(\d$)/$2/;
          $ret .= $tens[$tmp];
          if ($tmp > 0) {
            $ret .= " ";
          }
          $tmp = 5;
        }
      }
    }

    $ret .= ' ';
    if ($tmp == 1) {
      $ret .= ($ones[ $i - 1 ]) ? $ones[ $i - 1 ] : $money_unit_names[0];
    }
    elsif ($tmp > 1 && $tmp < 5) {
      $ret .= ($twos[ $i - 1 ]) ? $twos[ $i - 1 ] : $money_unit_names[0];
    }
    elsif ($tmp > 4) {
      $ret .= ($fifth[ $i - 1 ]) ? $fifth[ $i - 1 ] : $money_unit_names[0];
    }
    else {
      $ret .= ($fifth[$i-1]) ? $fifth[$i-1] : $money_unit_names[0];
    }
    $ret .= ' ';
  }

  if ($second ne '') {
    $ret .= " $second  ". (( $money_unit_names[1] ) ? $money_unit_names[1] : '');
  }
  else {
    $ret .= "";
  }

  use locale;
  my $locale = $attr->{LOCALE} || 'ru_RU.CP1251';
  setlocale( LC_ALL, $locale );
  $ret = ucfirst $ret;
  setlocale( LC_NUMERIC, "" );

  return $ret;
}

#**********************************************************
=head2 decode_base64()

=cut
#**********************************************************
sub decode_base64 {
  local ($^W) = 0;    # unpack("u",...) gives bogus warning in 5.00[123]
  my $str = shift;
  my $res = "";

  $str =~ tr|A-Za-z0-9+=/||cd;    # remove non-base64 chars
  $str =~ s/=+$//;                # remove padding
  $str =~ tr|A-Za-z0-9+/| -_|;    # convert to uuencoded format
  while ($str =~ /(.{1,60})/gs) {
    my $len = chr(32 + length($1) * 3 / 4);    # compute length byte
    $res .= unpack("u", $len . $1);            # uudecode
  }

  return $res;
}

#**********************************************************
=head2 encode_base64()

=cut
#**********************************************************
sub encode_base64 {

  if ($] >= 5.006) {
    require bytes;
    if (bytes::length($_[0]) > length($_[0])
      || ($] >= 5.008 && $_[0] =~ /[^\0-\xFF]/))
    {
      require Carp;
      Carp::croak("The Base64 encoding is only defined for bytes");
    }
  }

  require integer;
  integer->import();

  my $eol = $_[1];
  $eol = "\n" unless defined $eol;

  my $res = pack("u", $_[0]);

  # Remove first character of each line, remove newlines
  $res =~ s/^.//mg;
  $res =~ s/\n//g;

  $res =~ tr|` -_|AA-Za-z0-9+/|;    # `# help emacs
                                    # fix padding at the end
  my $padding = (3 - length($_[0]) % 3) % 3;
  $res =~ s/.{$padding}$/'=' x $padding/e if $padding;

  # break encoded string into lines of no more than 76 characters each
  if (length $eol) {
    $res =~ s/(.{1,72})/$1$eol/g;
  }

  return $res;
}

#**********************************************************
=head2 check_time() - time check function. Make start time point

=cut
#**********************************************************
sub check_time {
  my $begin_time = 0;

  #Check the Time::HiRes module (available from CPAN)
  eval { require Time::HiRes; };
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }

  return $begin_time;
}

#**********************************************************
=head2 gen_time($begin_time) - Show generation time

  Arguments:
    $begin_time  - Start time point
    $attr
      TIME_ONLY

  Returns:
    generation time

=cut
#**********************************************************
sub gen_time {
  my ($begin_time, $attr) = @_;

  if ($begin_time > 0) {
    Time::HiRes->import(qw(gettimeofday));
    my $end_time = Time::HiRes::gettimeofday();
    return (($attr->{TIME_ONLY}) ? '' : 'GT: ') . sprintf("%2.5f", $end_time - $begin_time);
  }

  return '';
}

#**********************************************************
=head2 clearquotes($text, $attr) - For clearing quotes

=cut
#**********************************************************
sub clearquotes {
  my ($text, $attr) = @_;

  if ($text ne '""') {
    my $extra = $attr->{EXTRA} || '';
    $text =~ s/\"$extra//g;
  }
  else {
    $text = '';
  }

  return $text;
}

#**********************************************************
=head2 tpl_parse($string, \%HASH_REF, $attr); - Parse tpl

  Arguments:
    $string   - parse string
    $HASH_REF - Hash_ref of parameters
    $attr     - Extra attributes
      SET_ENV - Set enviropment values

  Return:
    result string

=cut
#**********************************************************
sub tpl_parse {
  my ($string, $HASH_REF, $attr) = @_;

  while (my ($k, $v) = each %$HASH_REF) {
    if (!defined($v)) {
      $v = '';
    }
    $string =~ s/\%$k\%/$v/g;
    if ($attr->{SET_ENV}) {
      $ENV{$k}=$v;
    }
  }

  return $string;
}

#**********************************************************
=head2 cmd($cmd, \%HASH_REF); - Execute shell command

command execute in backgroud mode without output

  Arguments:

    $cmd     - command for execute
    $attr    - Extra params
      PARAMS          - Parameters for command line (HASH_REF)
        [PARAM_NAME => PARAM_VALUE] convert to PARAM_NAME="PARAM_VALUE"
      SHOW_RESULT     - show output of execution
      timeout         - Time for command execute (Default: 5 sec.)
      RESULT_ARRAY    - Return result as ARRAY_REF
      ARGV            - Add ARGV for program
      DEBUG           - Debug mode

      $ENV{CMD_EMULATE_MODE}
         /usr/abills/var/log/cmd.log

  Returns:

    return command result string

  Examples:

    my $result = cmd("/usr/abills/misc/extended.sh %LOGIN% %IP%", { PARAMS => { LOGIN => text } });

    run as:

    /usr/abills/misc/extended.sh test


    my $result = cmd("/usr/abills/misc/extended.sh", { ARGV => 1, PARAMS => { LOGIN => text } });

    run as:

    /usr/abills/misc/extended.sh LOGIN="test"

=cut
#**********************************************************
sub cmd {
  my ($cmd, $attr) = @_;

  my $debug   = $attr->{DEBUG} || 0;
  my $timeout = defined($attr->{timeout}) ? $attr->{timeout} : 5;
  my $result  = '';

  my $saveerr;
  my $error_output;
  #Close error output
  if (! $attr->{SHOW_RESULT} && ! $debug) {
    open($saveerr, '>&', \*STDERR);
    close(STDERR);
    #Add o scallar error message
    open STDERR, '>', \$error_output or die "Can't make error scalar variable $!?\n";
  }

  if ($debug > 1) {
    $attr->{PARAMS}{DEBUG}=$debug;
  }

  if ($attr->{PARAMS}) {
    $cmd = tpl_parse($cmd, $attr->{PARAMS}, { SET_ENV => $attr->{SET_ENV} });
  }

  if ($attr->{ARGV}) {
    my @skip_keys = ('EXT_TABLES', 'SEARCH_FIELDS', 'SEARCH_FIELDS_ARR', 'SEARCH_FIELDS_COUNT',
      'COL_NAMES_ARR', 'db', 'list', 'dbo', 'TP_INFO', 'TP_INFO_OLD', 'CHANGES_LOG', '__BUFFER', 'TABLE_SHOW');
    foreach my $key ( sort keys %{ $attr->{PARAMS} } ) {
      next if (in_array($key, \@skip_keys));
      $cmd .= " $key=\"$attr->{PARAMS}->{$key}\"";
    }
  }

  if($debug>2) {
    print $cmd."\n";
    if ($debug > 5) {
      return $result;
    }
  }

  if($ENV{CMD_EMULATE_MODE}) {

    my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
    my $TIME = POSIX::strftime("%H:%M:%S", localtime(time));
    if (open(my $fh, '>>', '/usr/abills/var/log/cmd.log')) {
       print $fh "$DATE $TIME " . $cmd ."\n";
     close($fh);
    }
    else {
      die "Can't open '/usr/abills/var/log/cmd.log' $!\n";
    }

    if ($ENV{CMD_EMULATE_MODE} > 1) {
      return [];
    }
  }

  eval {
    local $SIG{ALRM} = sub { die "alarm\n" };    # NB: \n required

    if ($timeout) {
      alarm $timeout;
    }

    #$result = system($cmd);
    $result = `$cmd`;
    alarm 0;
  };

  if ($@) {
    die unless $@ eq "alarm\n";                  # propagate unexpected errors
    print "timed out\n" if ($debug>2);
  }
  elsif($!) {
    $result = $cmd . " : " . $!
  }
  else {
    print "NO errors\n" if ($debug>2);
  }

  if ($debug) {
    print $result;
  }

  if ($saveerr) {
    close(STDERR);
    open(STDERR, '>&', $saveerr);
  }

  if($attr->{RESULT_ARRAY}) {
    my @result_rows = split(/\r\n/, $result);
    return \@result_rows
  }

  return $result;
}

#**********************************************************
=head2 ssh_cmd($cmd, $attr) - Make ssh command

  Arguments:

    $cmd     - command for execute
      extra cmd "sleep 10"
    $attr    - Extra params
      NAS_MNG_IP_PORT  - Server IP:PORT:SSH_PORT
      BASE_DIR         - Base dir for certificate BASE_DIR/Certs/id_rsa
      NAS_MNG_USER     - ssh login (Default: abills_admin)
      SSH_CMD          - ssh command (Default: /usr/bin/ssh -p $nas_port -o StrictHostKeyChecking=no -i $base_dir/Certs/id_rsa.$nas_admin)
      SSH_KEY          - (optional) custom certificate file
      SSH_PORT         - Custom ssh port
      DEBUG            - Debug mode

  Returns:

    return array_ref

  Examples:

    my $result = ssh_cmd('ls', { NAS_MNG_IP_PORT => '192.168.0.12:22' });

    make

    /usr/bin/ssh -p 22 -o StrictHostKeyChecking=no -i /usr/abills/Certs/id_rsa.abills_admin abills_admin@192.168.0.12 '$cmd'

=cut
#**********************************************************
sub ssh_cmd {
  my ($cmd, $attr) = @_;

  my $debug     = $attr->{DEBUG} || 0;
  my @value = ();

  if (! $attr->{NAS_MNG_IP_PORT}) {
    print "Error: NAS_MNG_IP_PORT - Not defined\n";
    return \@value;
  }

  # IP : POD/COA : SSH/TELNET : SNMP port
  my @mng_array = split(/:/, $attr->{NAS_MNG_IP_PORT});
  my $nas_host  = $mng_array[0];
  my $nas_port  = 22;

  if($attr->{SSH_PORT}) {
    $nas_port=$attr->{SSH_PORT};
  }
  elsif ($#mng_array > 1) {
    $nas_port=$mng_array[2];
  }

  $nas_port //= 22;

  my $base_dir = $attr->{BASE_DIR} || '/usr/abills/';
  
  # Check for KnownHosts file
  my $known_hosts_file = "$base_dir/Certs/known_hosts";
  my $known_hosts_option = " -o UserKnownHostsFile=$known_hosts_file"
   ." -o CheckHostIP=no";
  
  my $nas_admin = $attr->{NAS_MNG_USER}|| 'abills_admin';
  my $ssh_key   = $attr->{SSH_KEY}     || "$base_dir/Certs/id_rsa." . $nas_admin;
  my $SSH       = $attr->{SSH_CMD}     || "/usr/bin/ssh -q -p $nas_port $known_hosts_option"
                                            . " -o StrictHostKeyChecking=no -i " . $ssh_key;
  
  my @cmd_arr = ();
  if (ref $cmd eq 'ARRAY') {
    @cmd_arr = @{ $cmd };
  }
  else {
    push @cmd_arr, $cmd ;
  }

  foreach my $run_cmd (@cmd_arr) {
    $run_cmd =~ s/[\r\n]+/ /g;

    if ($run_cmd =~ /sleep (\d+)/) {
      sleep $1;
      next;
    }

    my $cmds = "$SSH $nas_admin\@$nas_host '$run_cmd'";

    if ($debug) {
      print "$cmds\n";
    }

    open(my $ph, '-|', "$cmds") || die "Can't open '$cmds' $!\n";
      @value = <$ph>;
    close($ph);

    if ($debug > 2) {
      print join("\n", @value);
    }
  }

  return \@value;
}

#**********************************************************
=head2 date_diff($from_date, $to_date) - period in days from date1 to date2

  Arguments:

    $from_date - From date
    $to_date   - To date

  Returns:

    integer of date

  Examples:

    my $days = date_diff('2015-10-31', '2015-12-01');

=cut
#**********************************************************
sub date_diff {
	my ($from_date, $to_date) = @_;

  my ($from_year, $from_month, $from_day) = split(/-/, $from_date, 3);
  my ($to_year,   $to_month,   $to_day)   = split(/-/, $to_date,   3);
  my $from_seltime = POSIX::mktime(0, 0, 0, $from_day, ($from_month - 1), ($from_year - 1900));
  my $to_seltime   = POSIX::mktime(0, 0, 0, $to_day,   ($to_month - 1),   ($to_year - 1900));

  my $days = int(($to_seltime - $from_seltime) / 86400);

	return $days;
}

#**********************************************************
=head2 date_format($date, $format, $attr) - convert date to other date format

  Arguments:

    $date     - Input date YYYY-MM-DD
    $format   - Output format (Use POSIX conver format)
    $attr     -  Extra atributes

  Returns:

    string of date

  Examples:

    date_format('2015-10-31 08:01:15', "%m.%d.%y");

    result 31.10.2015

    date_format('2015-10-31 08:01:15', "%H-%m-%S");

    result 08-01-15

=cut
#**********************************************************
sub date_format {
  my ($date, $format) = @_;
  my $year   = 0;
  my $month  = 0;
  my $day    = 0;
  my $hour   = 0;
  my $min    = 0;
  my $sec    = 0;

  if ($date =~ /(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
    $year   = $1 - 1900;
    $month  = $2 - 1;
    $day    = $3;
    $hour   = $4;
    $min    = $5;
    $sec    = $6;
  }
  elsif ($date =~ /^(\d{4})\-(\d{2})\-(\d{2})$/) {
    $year   = $1 - 1900;
    $month  = $2 - 1;
    $day    = $3;
  }
  else {
    ($sec, $min, $hour, $day, $month, $year) = (localtime time)[ 0, 1, 2, 3, 4, 5 ];
    $year = "0$year"  if ($year < 10);
    $day  = "0$day"   if ($day < 10);
    $month= "0$month" if ($month < 10);
    $hour = "0$hour"  if ($hour < 10);
    $min  = "0$min"   if ($min < 10);
    $sec  = "0$sec"   if ($sec < 10);
  }

  $date = POSIX::strftime( $format,
                  localtime(POSIX::mktime($sec, $min, $hour, $day, $month, $year) ) );

  return $date;
}

#**********************************************************
=head2 _bp($attr) - Break points for debugging

  Show file name,line number of point and input value

  Arguments:
    $explanation - Describe of value or hash_ref(legacy)
      HEADER     - show html header (Content-Type)
      SHOW       - Show input. Auto detect: string, array_ref, hash_ref, obj
      EXIT       - Exit programs
      BREAK_LINE - Break line symbols
    $value       - Value of any type STRING, ARR_REF, HASH_REF
    $attr        - hash_ref
      HEADER         - print HTTP content-type header
      EXIT           - Exit program (!!!)
      BREAK_LINE     - Break line symbols
      TO_WEB_CONSOLE - print to browser debug console via JavaScript
      TO_CONSOLE     - print without HTML formatting
      IN_JSON        - surround with JSON comment tags ( used only with IN_CONSOLE )
      
      SORT           - Sort hash keys

  Returns:
    1

  Example:
    my $hash = { id1 => 'value1' };

    Show with explanation of value
      _bp( 'Simple hash', $hash, $attr ) if ($attr->{DEBUG});
      _bp("Simple hash", $hash);

    Show value in browser console
      _bp("Simple hash", $hash, { TO_WEB_CONSOLE => 1 });

    No HTML formatting
      _bp("Simple hash", $hash, { TO_CONSOLE => 1 });

    Legacy:
      _bp({ SHOW => 'Some text' });

=cut
#**********************************************************
sub _bp {
  my ($explanation, $value, $attr) = @_;

  # Allow to set args one time for all cals
  state $STATIC_ARGS;
  if ($attr && $attr->{SET_ARGS}){
    $STATIC_ARGS = $attr->{SET_ARGS};
    return;
  }
  if (!$attr && defined $STATIC_ARGS){
    $attr = $STATIC_ARGS;
  }

  my $result_string = "";
  my ($package, $filename, $line) = caller;

  my $break_line = "\n";

  # Legacy for old _bp call
  if ( ref $explanation eq 'HASH' ){
    $attr = $explanation;
    $value = $attr->{SHOW};
    $explanation = "Breakpoint";
    print $value;
  }

  if ( ref $value ne '' ){
    require Data::Dumper;
    Data::Dumper->import();

    if ( $attr->{SORT} && ref $value eq 'HASH' ){
      foreach my $key ( sort { $a <=> $b } keys %$value ) {
        print "$key -> $value->{$key} $break_line";
      }
    }
    else{
      unless ( $attr->{TO_CONSOLE} || $attr->{TO_WEB_CONSOLE} ){
        $Data::Dumper::Pad = "<br>\n";
        $Data::Dumper::Indent = 3;
      }
      $result_string = Data::Dumper::Dumper( $value );
    }
  }
  else{
    $result_string = $value || '';
  }

  if ( $attr->{HEADER} ){
    print "Content-Type: text/html\n\n";
  }

  if ( $attr->{TO_WEB_CONSOLE} ){
    $break_line = ($attr->{BREAK_LINE}) ? $attr->{BREAK_LINE} : "";

    my $log_explanation = uc ( $explanation );
    my $log_string = $result_string;

    $log_string =~ s/\n/$break_line/g;
    $log_string =~ s/\s+/ /g;
    $log_string =~ s/\"/\'/g;

    my $string_for_eval = qq/var log_str = "$log_string" ;eval ('console.log(log_str)') /;
    print qq\<script>try{console.group('[ $filename : $line ] $log_explanation'); $string_for_eval; console.groupEnd();} catch (E) {console.log('DEBUG ERROR: ' + E)} </script>\;
  }
  elsif ( $attr->{TO_CONSOLE} ){
    my $console_log_string = "[ $filename : $line ] $break_line" . uc ( $explanation ) . " : " . $result_string . $break_line;

    if ( $attr->{BREAK_LINE} ){
      $console_log_string =~ s/[\n]/$attr->{BREAK_LINE}/g;
    }
    
    if ($attr->{IN_JSON}){
      $console_log_string = " /* \n $console_log_string \n */ ";
    }
    
    print $console_log_string . "\n";
  }
  else{
    $break_line = ($attr->{BREAK_LINE}) ? $attr->{BREAK_LINE} : "<br/>\n";

    $result_string =~ s/\s/\&nbsp\;/g;

    my $html_log_string = "<hr/><div class='text-left'><b>[ $filename : $line ]</b>$break_line" . uc ( $explanation ) . " : " . $result_string . "</div>";
    print $html_log_string . "\n";
  }

  if ( $attr->{EXIT} ){
    print "$break_line Exit on breakpoint: PACKAGE: '$package', FILE:  '$filename', LINE: '$line' ";
    if ($attr->{TO_WEB_CONSOLE}){
      print "$break_line Show to Browser console";
    }
    exit ( 1 );
  }

  return 1;
}

#**********************************************************
=head2 urlencode($text) URL encode function

  Arguments:
    $text   - Text string

  Returns:
    Encoding string

=cut
#**********************************************************
sub urlencode {
  my ($text) = @_;

  #$s =~ s/ /+/g;
  #$s =~ s/([^A-Za-z0-9\+-])/sprintf("%%%02X", ord($1))/seg;
  $text =~ s/([^A-Za-z0-9\_.-])/sprintf("%%%2.2X", ord($1))/ge;

  return $text;
}

#**********************************************************
=head2 urldecode($text) URL decode function
  Arguments:
    $text   - Text string

  Returns:
    decoding string

=cut
#**********************************************************
sub urldecode {
  my ($text) = @_;

  $text =~ s/\+/ /g;
  $text =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;

  return $text;
}

#**********************************************************
=head2 startup_files($attr) - Get deamon startup information and other params of system

Analise file /usr/abills/Abills/programs and return hash_ref of params

  Atributes:
    $attr
      TPL_DIR

  Returns:
    hash_ref

=cut
#**********************************************************
sub startup_files {
	my ($attr) = @_;

  my %startup_files = ();
  our $base_dir;
  $base_dir //= '/usr/abills/';
  
	my $startup_conf = $base_dir . '/Abills/programs';
	if ( $attr->{TPL_DIR} ) {
	  if (-e "$attr->{TPL_DIR}/programs.tpl") {
	    $startup_conf = "$attr->{TPL_DIR}/programs.tpl";
	  }
	}

  my $content = '';
  if(lc($^O) eq 'freebsd') {
    %startup_files = (
      WEB_SERVER_USER    => "www",
      RADIUS_SERVER_USER => "freeradius",
      APACHE_CONF_DIR    => '/usr/local/apache22/Include/',
      RESTART_MYSQL      => '/usr/local/etc/rc.d/mysql-server',
      RESTART_RADIUS     => '/usr/local/etc/rc.d/freeradius',
      RESTART_APACHE     => '/usr/local/etc/rc.d/apache22',
      RESTART_DHCP       => '/usr/local/etc/rc.d/isc-dhcp-server',
      SUDO               => '/usr/local/bin/sudo',
    );
  }
  else {
    %startup_files = (
      WEB_SERVER_USER    => "www-data",
      APACHE_CONF_DIR    => '/etc/apache2/sites-enabled/',
      RADIUS_SERVER_USER => "freerad",
      RESTART_MYSQL      => '/etc/init.d/mysqld',
      RESTART_RADIUS     => '/etc/init.d/freeradius',
      RESTART_APACHE     => '/etc/init.d/apache2',
      RESTART_DHCP       => '/etc/init.d/isc-dhcp-server',
      SUDO               => '/usr/bin/sudo',
    );
  }

  if ( -f $startup_conf ) {
	  if (open(my $fh, '<', "$startup_conf") ) {
		  while( <$fh> ) {
			  $content .= $_;
		  }
	    close($fh);
	  }

  	my @rows = split(/[\r\n]+/, $content);
	  foreach my $line (@rows) {
	    my ($key, $val) = split(/=/, $line, 2);
  	  next if (!$key);
	    next if (!$val);
	    if ($val =~ /^([\/A-Za-z0-9\_\.\-]+)/) {
	      $startup_files{$key}=$val;
	    }
	  }
  }

  return \%startup_files;
}

#**********************************************************
=head2 days_in_month($attr)

  Arguments:
    $attr
      DATE

  Returns:
    $day_in_month

  Examples:

    days_in_month({ DATE => '2016-11' });

    days_in_month({ DATE => '2016-11-01' });

=cut
#**********************************************************
sub days_in_month {
  my ($attr) = @_;

  my $DATE = '';

  if ($attr->{DATE}) {
    $DATE = $attr->{DATE};
  }
  else {
    $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
  }

  my ($Y, $M) = split(/-/, $DATE);

  my $day_in_month = ($M != 2 ? (($M % 2) ^ ($M > 7)) + 30 : (!($Y % 400) || !($Y % 4) && ($Y % 25) ? 29 : 28));

  return $day_in_month;
}

#**********************************************************
=head2 next_month($attr)

  Arguments:
    $attr
      DATE      - Curdate
      END       - End off month
      PERIOD    - Month period
      DAY

  Return:
    $next_month (YYYY-MM-DD)

  Examples:
    next_month({ DATE => '2016-03-12' });

=cut
#**********************************************************
sub next_month {
  my ($attr) = @_;

  my $DATE = '';
  my $next_month = '';

  if ($attr->{DATE}) {
    $DATE = $attr->{DATE};
  }
  else {
    $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
  }

  my ($Y, $M, $D) = split(/-/, $DATE);

  if($attr->{PERIOD}) {
    if($attr->{END}) {
      $attr->{PERIOD} += 30;
    }

    $next_month = POSIX::strftime( '%Y-%m-%d', localtime(POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + ($attr->{PERIOD}+1) * 86400));

    return $next_month;
  }

  if ($M + 1 > 12) {
    $M = 1;
    $Y++;
  }
  else {
    $M++;
  }

  $D = '01';
  if($attr->{DAY}) {
    $D = $attr->{DAY};
  }
  elsif($attr->{END}) {
    $D = ($M != 2 ? (($M % 2) ^ ($M > 7)) + 30 : (!($Y % 400) || !($Y % 4) && ($Y % 25) ? 29 : 28));
  }

  $next_month = sprintf("%4d-%02d-%02d", $Y, $M, $D);

  return $next_month;
}

#**********************************************************
=head2 show_hash($hash, $attr) - show hash

  Arguments:
    $hash_ref
    $attr
      DELIMITER
      OUTPUT2RETURN

  Results:
    True or false

=cut
#**********************************************************
sub show_hash {
  my($hash, $attr) = @_;

  if(ref $hash ne 'HASH') {
    return 0;
  }

  my $result = '';
  foreach my $key (sort keys %$hash) {
    $result .= "$key - ";
    if (ref $hash->{$key} eq 'HASH') {
      $result .= show_hash($hash->{$key}, { %{ ($attr) ? $attr : {}}, OUTPUT2RETURN => 1 });
    }
    elsif(ref $hash->{$key} eq 'ARRAY') {
      foreach my $key_ (@{ $hash->{$key} }) {
        if(ref $key_ eq 'HASH') {
          $result .= show_hash($key_, { %{ ($attr) ? $attr : {}}, OUTPUT2RETURN => 1 });
        }
        else {
          $result .= $key_;
        }
      }
    }
    else {
      $result .= (defined($hash->{$key})) ? $hash->{$key} : q{};
    }
    $result .= ($attr->{DELIMITER} || ',');
  }

  if ($attr->{OUTPUT2RETURN}) {
    return $result;
  }

  print $result;

  return 1;
}

#**********************************************************
=head2 load_pmodule($modulename, $attr); - Load perl module

  Arguments:
    $modulename   - Perl module name
    $attr
      IMPORT      - Function for import
      HEADER      - Add Content-Type header
      SHOW_RETURN - Result to return

  Returns:
    TRUE - Not loaded
    FALSE - Loaded

  Examples:

    load_pmodule('Simple::XML');

=cut
#**********************************************************
sub load_pmodule2 {
  my ($name, $attr) = @_;

  eval " require $name ";

  my $result = '';

  if (!$@) {
    if ($attr->{IMPORT}) {
      $name->import( $attr->{IMPORT} );
    }
    else {
      $name->import();
    }
  }
  else {
    $result = "Content-Type: text/html\n\n" if ($attr->{HEADER});
    $result .= "Can't load '$name'\n".
      " Install Perl Module <a href='http://abills.net.ua/wiki/doku.php/abills:docs:manual:soft:$name' target='_install'>$name</a> \n".
      " Main Page <a href='http://abills.net.ua/wiki/doku.php/abills:docs:other:ru?&#ustanovka_perl_modulej' target='_install'>Perl modules installation</a>\n".
      " or install from <a href='http://www.cpan.org'>CPAN</a>\n";

    $result .= "$@" if ($attr->{DEBUG});

    #print "Purchase this module http://abills.net.ua";
    if ($attr->{SHOW_RETURN}) {
      return $result;
    }
    elsif (! $attr->{RETURN} ) {
      print $result;
      die;
    }

    print $result;
  }

  return 0;
}

#**********************************************************
=head2 date_inc($date)

  Arguments:
    $date - '2016-01-24'

  Returns:
   string - date incremented by one day

   0 if incorrect date;

=cut
#**********************************************************
sub date_inc {
  my ($date) = @_;

  my ($year, $month, $day) = split ('-', $date, 3);
  return 0 unless ( $year && $month && $day );

  if ( ++$day >= 29 ){
    my $days_in_month = days_in_month( {DATE => $date} );
    if ( $day > $days_in_month ){
      if ( ++$month == 13 ){
        $year++;
        $month = '01';
      }
      $day = '01';
    }
  }

  return "$year-$month-$day";
}

=head1 AUTHOR

~AsmodeuS~ (http://abills.net.ua/)

=cut

1;
