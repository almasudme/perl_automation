

#!/usr/local/lib/perl_stable/bin/perl
#
# ------------------------------------------------------------
# -- Convert an hdf file to a fake f06 file
# -- Author Mir AL-Masud
# ------------------------------------------------------------
#
BEGIN
{
    use File::Basename;
    $path = dirname($0);
    $path =~ s|\\|\/|g;

    push( @INC, ".", $ENV{'NXN_TOOLS'},
                     "/plm/cinas/cae_nxn/nastran_tools/bin",
                     "//plm/cinas/cae_nxn/nastran_tools/bin",
					 "d:\\view\\mir_12_ucp\\nastran2\\qatools");
}

use strict;
use Time::HiRes;
use NxnHF;
use File::Copy qw(copy);
use POSIX;

while(@ARGV){
  my $sFile = shift (@ARGV);
  my $sHdf="out/".$sFile.".hdf";
  print "Starting conversion of hdf5 ... ";
  
  #-- load hdf5 tools library for linux
  if ($^O =~/linux/ ){
    unless (-f "libhdf5.so.8"){
	  print "Loading h5dump library ...\n";
      copy ("/plm/cinas/cae_nxn/nastran_tools/bin/libhdf5.so.8.0.2", "libhdf5.so.8");
    }  
    
    (-f "libhdf5.so.8") ? print "h5dump tools library loaded.\n" : "failed to load hdf5 tools library\n";
  }
  
  
  open (STDOUT,">out/".$sFile."_h\.n")|| die "could not create the ".$sFile."\.n";
  
  Greeter("header");
  print "\n\t".$sFile.": ".localtime()."\n";
  ##
    my @aDatasets;
    getDatasetOfGroup($sHdf,\@aDatasets);
    foreach (@aDatasets){
      # Print Model Data
      if (/^\/model/){
        printf("%50s\n\n","M O D E L  D A T A");
        my @aData = getData($sHdf, $_);
        splitPrintData(\@aData,$_);
      }
      # Print Results Data
      if (/^\/results/){
        printf("%50s\n\n","R E S U L T S");
        my @aData = getData($sHdf, $_);
        splitPrintData(\@aData,$_);
      }
    }
  ##  
    Greeter("footer");
  
  close(STDOUT);  
  print " done. $sFile\.n created.\n";
}

`rm libhdf5.so.8` if ($^O =~/linux/ );
