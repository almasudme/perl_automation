
BEGIN
{
    use File::Basename;
    $path = dirname($0);
    $path =~ s|\\|\/|g;

    push( @INC, ".", $ENV{'NXN_TOOLS'}, $ENV{'NXN_TOOLS_QA'},
                "/plm/cinas/cae_nxn/nastran_tools/bin",
                "//plm/cinas/cae_nxn/nastran_tools/bin" );
}
use strict;
use qa_util;
use nxn;
use nxnBuild;
use List::Util 'sum';
use File::Basename;
use File::Copy;
use Cwd;
use Getopt::Long;

my $optCp = undef;
my $optS = undef;
my $optHelp = undef;
my $optTestOnly =undef;
my $optN = undef;
my $optVer = undef;
my %optList = (
  "cp=s"	=>	\$optCp,
  "s=s"	=>	\$optS,
  "n=s" => \$optN,
  "1" => \$optTestOnly,
  "ver=s"=> \$optVer,
  "help" => \$optHelp
  );
  
GetOptions(%optList);
usage() if ($optHelp);
#my $value_count = sum values %words;
unless ($optVer){
    $optVer = $ENV{'NXN_TOOLS_VER'};
};
my @aBuilds = getStableGBs($optVer,$optN);

my $sDir= "//plm/cinas/cae_nxn/nx_nast_stats/predev_testing/";
my %rFail;
my $i = 0;
print join(" " , @aBuilds);
foreach my $sBuild (@aBuilds){
  
  
  
  my $sXml = $sDir.$sBuild."/emt690lp/xml/ucpsummary.xml";
  print $sXml."\n" unless ($optTestOnly);
  
  unless(open (XML,"<".$sXml)) {
    warn "Could not load $sXml \n";
    next;
  }
   # $i++;
  my $sId ;
  my $sStatus;
  while (<XML>){
  if (/<case_name>(\S+)</){
    $sId = $1;
  } elsif (/<comment>Match\s(\S+)\_em/i){
    $sStatus = 1 ;
    %rFail->{$sId}->{$sBuild}=$sStatus
  } else {
    next;
  }

  }
    close(XML);
    
}

my @aTestsToBench;


foreach (keys(%rFail)){
 my $sSum = sum values (%{$rFail{$_}});
  if ($sSum >($#aBuilds)){
    push(@aTestsToBench,$_);
  }
}

my @aBench = join (" ",@aTestsToBench);
print @aBench;
print "\n Total: ".scalar(@aTestsToBench). " Failures matched at least ".(scalar(@aBuilds))." times.\n " unless ($optTestOnly);




sub usage {
    print(
    '
    perl matched.pl -m em64tL -b 2007.43 -n 20
    ');
}
