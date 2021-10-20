
#!/usr/local/lib/perl_stable/bin/perl
#
# ------------------------------------------------------------
# -- Convert an hdf file to a fake .f06/.n file
# -- Author Mir Al-Masud 
# ------------------------------------------------------------
#
package NxnHF;
require Exporter;
@ISA    = qw( Exporter );
@EXPORT = qw( Greeter printData getAnchors
          printHeader printSubcase getDatasetOfGroup getData splitPrintData);

use strict;
use NxnHF;
use POSIX;

sub numIdHeader{
  my $sHeader = shift;
  return 3 if ($sHeader =~ /OES1:STRESS:CQUAD8/i);
  return 3 if ($sHeader =~ /OES1:STRESS:CTRIA6_CENTER/i);
  return 3 if ($sHeader =~ /OES1X1:STRESS:CQUAD8/i);
  return 3 if ($sHeader =~ /OES1X1:STRESS:CTRIA6_CENTER/i); 
  return 3 if ($sHeader =~ /OES2:STRESS:CQUAD8/i);   
  return 3 if ($sHeader =~ /OES2:STRESS:CTRIA6_CENTER/i);    
  return 3 if ($sHeader =~ /OSTR1X:STRAIN:CTRIA6_CENTER/i);
  return 3 if ($sHeader =~ /OSTR1X:STRAIN:CQUAD8/i);
  return 3 if ($sHeader =~ /OSTR2:STRAIN:CTRIA6_CENTER/i);  
  return 1;
}

#-------------------------------------------------------------
# Func : printData - processes bulk data and arrange them to a 
#        printable row x column format
# Arg  : $0 input bulk data from parsed xml   
#-------------------------------------------------------------
sub printData {
  my $sData = shift;
  my $sField = shift;
  my $sSubcase =shift;
  my $sHeader = shift;
     #$sData =~ s/\"//g;
  my @aRow = split("\n",$sData);
  
  
  if (length $aRow[1] > 112){
    printLongData($sData,$sField,$sSubcase,$sHeader) ;
	return;
  }
  
  if ($sField){
    printSubcase($sSubcase);
    printHeader($sHeader);
    printData($sField) 
  };
  
  #printing data
   foreach my $sRow (@aRow){
     print " ";
     my @aData = split(" ",$sRow);
	 foreach  (@aData){
	   my $sTemp = $_;
	      #$sTemp = "0.0" if ($_ =~/^\s*0$/ );
		  #$sTemp = "0.0" if ($_ =~/E\-\d\d\d/i);
		  #$sTemp = $1.".0" if ($_ =~ /^(\-\d+$)/);
		  next if ($_ =~ /^\"$/);
	   printf "%14s ",$sTemp;
	 }
	 print "\n";
   }
}

#-------------------------------------------------------------
# Func : printHeader - processes the group header from hdf5 file
#        to legible Block Header 
# Arg  : $0 group name/header  from parsed xml   
#-------------------------------------------------------------
sub printHeader {
  my $sData = shift;
     $sData =~ s/\"|\///g;
	 $sData = uc $sData;
	 
  my @aRow = split(":",$sData);
  
  print "\t".$aRow[$#aRow-1]. " = ".$aRow[$#aRow]."\n";
  
  print "\t";
  my $i=0;
  
  while ($i<($#aRow-1)){
    print $aRow[$i]." ";
	$i++;
  }  
  
   print "\n\n";
}


#-------------------------------------------------------------
# Func : printSubcase - processes the group header from hdf5 file
#        to legible Subcase Header 
# Arg  : $0 group name/header  from parsed xml   
#-------------------------------------------------------------
sub printSubcase {
  my $sData = shift;
     $sData =~ s/^\s//;
	 $sData = uc $sData;
	 
  my @aRow = split(":",$sData);
  
  print "\t".$aRow[$#aRow-1]. " = ".$aRow[$#aRow]."\n";
}

#-------------------------------------------------------------
# Func : Appends standard Header and footer so that UCP can 
#        recognize as a valid nastran results output
# Arg  : $0 "Header" or "footer"    
#-------------------------------------------------------------
sub Greeter {
  my $sWhat = shift;

  print '1 
    
                          Welcome to Nastran 
                          --------------------
    
    
   This "news" information can be turned off by setting "news=no" in the runtime
   configuration (RC) file.  The "news" keyword can be set in the system RC file
   for global, or multi-user control, and in a local file for local control.
   Individual jobs can be controlled by setting news to yes or no on the command
   line. The news file alone can be viewed with the command "eds1 nastran news".
   ' if ($sWhat =~/header/i);
  
  if ($sWhat =~/footer/i){
    print '1                                        * * * END OF JOB * * *' 
  };
  print "\n\n";
  
}

sub printLongData {
   my $sData = shift;
   my $sField = shift;
   my $sSubcase = shift;
   my $sHeader =shift;
     #$sData =~ s/\"//g;
   my @aRow = split("\n",$sData);
   my @aField = split(" ",$sField);

   shift(@aRow);
   pop(@aRow); 
   my @aBranch;
   my @aBranchField;
   my $iBranch=0;
   my $nBranch=0;
   
   
   foreach my $sRow (@aRow){
	 my $nInit=numIdHeader($sHeader);
     my $nEnd=8;my $iInc = $nEnd-numIdHeader($sHeader);
     my @aData = split(" ",$sRow);
	 my $iCount = 0;
	 my $sInit = "";
     my $sInitField = ""; 	 
	 for (my $i=0;$i<$nInit;$i++){
	   $sInit .= $aData[$i]." ";
	   $sInitField .= $aField[$i]." ";
	 }
	 
	 $nBranch = ceil((scalar(@aData)-$nInit)/($nEnd-$nInit));
	 
	 for (my $i=0;$i<$nBranch;$i++){
	   $aBranch[$iBranch][$i] = $sInit;
	   $aBranchField[$iBranch][$i] = $sInitField ;
	   for (my $j=$nInit;$j<$nEnd;$j++){
	     $aBranch[$iBranch][$i] .= $aData[$j]." ";
		 $aBranchField[$iBranch][$i] .= $aField[$j]." ";
	   }
	   
	   $nInit=$nInit+ $iInc;
	   $nEnd=$nEnd+$iInc;
#	   print $aBranch[$iBranch][$i]."\n";
	 }

	 $iBranch++;
   }
   
   
   
   for (my $i=0;$i<$nBranch;$i++){
     for(my $j=0;$j<scalar(@aRow);$j++){
       if ($j<1){
	   	 printSubcase($sSubcase); 
	     printHeader($sHeader);
	     printData($aBranchField[$j][$i]);	
         print "\n"		 
	   };
	   printData($aBranch[$j][$i]);
	 }
	 print "\n";
   }
   print "\n";
}

#-------------------------------------------------------------
# Func : Returns all the available dataset of a file 
#        
# Arg  : $0 Filepath
#      : $1 array reference  
#-------------------------------------------------------------

sub getDatasetOfGroup{  
	my $sGroup = shift;
  my $paDatasets = shift;
    #  $sGroup = chomp;
  my @aGroup = `h5ls $sGroup`;

foreach (@aGroup){
	if ($_ =~/(\S+)\s+Dataset/)  {
		#print $sGroup."/".$1."\n";
    my $sDataset = $sGroup."/".$1;
       $sDataset =~ s/(\S+\.hdf)//;
		push(@$paDatasets,$sDataset)
	} elsif ($_ =~/(\S+)\s+Group/) {
		getDatasetOfGroup($sGroup."/".$1,$paDatasets)
	}  
}

}
sub splitPrintData{
	my $paData = shift;
	my $sDataset = shift;
  my @aData = @$paData;
  my $nSplit = ceil(scalar(@{$aData[0]})/8);
  
  #---
  my @aAnchors = getAnchors($sDataset);

  my $sHeader = $sDataset;

  for (my $iSplit = 0;$iSplit<$nSplit;$iSplit++){
    if ($sDataset=~ /results/i){
      print "    ".$aAnchors[0]."\n";
      print "    ".$aAnchors[1]."\n";
      $sHeader = $aAnchors[2];
    }
  #---
      if ($nSplit>1){
        $sHeader =~ s/\// /g;
        printf("    %s_%s \n",uc($sHeader),$iSplit+1) ;
      } else {
        $sHeader =~ s/\// /g;
        printf("    %s \n",uc($sHeader)) ;
      }
    	
    foreach (@aData){
      next unless($_);
      my @aRow = @{$_};
    print("    ");
      for (my $i =$iSplit*8 ;$i<($iSplit+1)*8;$i++){
        printf("%14s", $aRow[$i]);
      }
      print "\n";
    }
    print "\n";
  }
return;
}
#-------------------------------------------------------------
# Func : Returns all the available dataset of a file 
#        
# Arg  : $0 Filepath
#      : $1 array reference  
#-------------------------------------------------------------
sub getData{
	my $sFile = shift;
	my $sDataset = shift;
	my @aDataset = `h5dump -m "%2.5E" -d $sDataset $sFile`;
	my @aData;
	my $i;
	my @aField;
  my $j=0;

	foreach (@aDataset){
			if (/^\s+(H5\S+)\s+\"(\S+)\"\;/){
			push(@aField, $2);
      } elsif (/^\s+\}\s+\"(\S+)\"\;/){
			push(@aField, $1);
			} elsif (/\((\d+)\)/){
				$i = $1;
			} elsif ($_ =~ /\s+\"*(.+)\,*$/ and $_ !~ /\{|\}|\;$/) {
				$aData[$i][$j] = $1;
        $aData[$i][$j] =~ s/\,$|\"$//;

        $j = $j+1;
			} elsif ($_ =~ /\}/){
        $j = 0;
      } elsif(/ATTRIBUTE/){
        last;
      }
	}
  #$sField =~ s/,$//;
  unshift(@aData,\@aField);
	return @aData;

}

# sub getData{
# 	my $sFile = shift;
# 	my $sDataset = shift;
# 	my @aDataset = `h5dump -d $sDataset $sFile`;
# 	my @aData;
# 	my $i;
# 	my $sField="";

# 	foreach (@aDataset){
    
# 			if (/^\s+(\S+)\s+\"(\S+)\"/){
# 			$sField .= $2.","
# 			} elsif (/\((\d+)\)/){
# 				$i = $1;
# 				$aData[$1] = "";				
# 			} elsif ($_ =~ /\s+(\S+\,*)/ and $_ !~ /\}/) {
# 				$aData[$i] .= $1;
# 			}
# 	}
#   $sField =~ s/,$//;
#   unshift(@aData,$sField);
# 	return @aData;

# }


sub getAnchors{
my $sHeader = uc(shift);
my @aTemp=split("/", $sHeader);
my $sAnchor;
my $sUcpBlock;

my @aAnchor;
for(my $i = 0;$i<scalar(@aTemp);$i++){
  if ($aTemp[$i] =~ /subcase/i){
    $aTemp[$i] =~ s/:/ = /;
  }
  elsif($aTemp[$i] =~ /(.+):(\S+):(\S+)/){
    $sAnchor = $2." = ".$3;
    $sUcpBlock = $1;
    $sUcpBlock =~ s/:/ /g;
  }

}
$aAnchor[0] = $aTemp[1]." ".$aTemp[2];
$aAnchor[1] = $sAnchor;
$aAnchor[2] =$sUcpBlock;

return @aAnchor;


}

1;
