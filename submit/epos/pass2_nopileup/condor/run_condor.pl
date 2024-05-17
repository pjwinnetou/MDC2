#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;

my $test;
GetOptions("test"=>\$test);
if ($#ARGV < 8)
{
    print "usage: run_condor.pl <events> <infile> <calo outfile>  <calo outdir> <global outfile> <global outdir> <trk outdir> <runnumber> <sequence>\n";
    print "options:\n";
    print "-test: testmode - no condor submission\n";
    exit(-2);
}

my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 52;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_pass2_nopileup_epos.sh",$rundir);
my $nevents = $ARGV[0];
my $infile = $ARGV[1];
my $calooutfile = $ARGV[2];
my $calodstoutdir = $ARGV[3];
my $globaloutfile = $ARGV[4];
my $globaldstoutdir = $ARGV[5];
my $trkdstoutdir = $ARGV[6];
my $runnumber = $ARGV[7];
my $sequence = $ARGV[8];
if ($sequence < 100)
{
    $baseprio = 90;
}
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("-%010d-%06d",$runnumber,$sequence);
my $logdir = sprintf("%s/log/run%d",$localdir,$runnumber);
if (! -d $logdir)
{
  mkpath($logdir);
}
my $condorlogdir = sprintf("/tmp/epos/pass2_nopileup/run%d",$runnumber);
if (! -d $condorlogdir)
{
  mkpath($condorlogdir);
}
my $jobfile = sprintf("%s/condor%s.job",$logdir,$suffix);
if (-f $jobfile)
{
    print "jobfile $jobfile exists, possible overlapping names\n";
    exit(1);
}
my $condorlogfile = sprintf("%s/condor%s.log",$condorlogdir,$suffix);
if (-f $condorlogfile)
{
    unlink $condorlogfile;
}
my $errfile = sprintf("%s/condor%s.err",$logdir,$suffix);
my $outfile = sprintf("%s/condor%s.out",$logdir,$suffix);
print "job: $jobfile\n";
open(F,">$jobfile");
print F "Universe 	= vanilla\n";
print F "Executable 	= $executable\n";
print F "Arguments       = \"$nevents $infile $calooutfile $calodstoutdir $globaloutfile $globaldstoutdir $trkdstoutdir $runnumber $sequence\"\n";
print F "Output  	= $outfile\n";
print F "Error 		= $errfile\n";
print F "Log  		= $condorlogfile\n";
print F "Initialdir  	= $rundir\n";
print F "PeriodicHold 	= (NumJobStarts>=1 && JobStatus == 1)\n";
#print F "accounting_group = group_sphenix.prod\n";
print F "accounting_group = group_sphenix.mdc2\n";
print F "accounting_group_user = sphnxpro\n";
print F "Requirements = (CPU_Type == \"mdc2\")\n";
print F "request_memory = 8192MB\n";
print F "Priority = $baseprio\n";
print F "job_lease_duration = 3600\n";
print F "Queue 1\n";
close(F);
#if (defined $test)
#{
#    print "would submit $jobfile\n";
#}
#else
#{
#    system("condor_submit $jobfile");
#}

open(F,">>$condorlistfile");
print F "$executable, $nevents, $infile, $calooutfile $calodstoutdir $globaloutfile $globaldstoutdir $trkdstoutdir, $runnumber, $sequence, $outfile, $errfile, $condorlogfile, $rundir, $baseprio\n";
close(F);
