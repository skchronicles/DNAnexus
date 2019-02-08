#!/bin/bash
# ccbr_fastqscreen_db2_array 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

main() {
	mkdir -p /data
	cd /data
	mv /*.tar.gz /data
	mkdir -p $HOME/out/OutTxt
	mkdir -p $HOME/out/OutPng
	mkdir -p $HOME/out/OutHtml
	tar xzvf *.tar.gz
(>&2 echo "DEBUG:Listing all files in data")
(>&2 tree /data)
(>&2 echo "Done listing")

	echo "Value of InFq: '${InFq[@]}'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

	for i in ${!InFq[@]}
	do
		infq=$(dx describe "${InFq[$i]}" --name)
		dx download "$InFq" -o $infq
	done
	
(>&2 echo "DEBUG:Listing all files in data")
(>&2 tree /data)
(>&2 echo "Done listing")

	cpus=`nproc`
	dx-docker run -v /data/:/data kopardev/ccbr_fastq_screen_0.13.0 fastq_screen --conf `ls *.conf` `ls *.fastq.gz|sort` --threads $cpus --subset 1000000 --aligner bowtie2
	
	for f in `ls *_screen.*`;do
	g=`echo $f|sed "s/_screen/_db2_screen/g"`
	mv $f $g
	done
	
(>&2 echo "DEBUG:Listing all files in data")
(>&2 tree /data)
(>&2 echo "Done listing")

	mv *.txt $HOME/out/OutTxt
	mv *.png $HOME/out/OutPng
	mv *.html $HOME/out/OutHtml

(>&2 echo "DEBUG:Listing all files in data")
(>&2 tree $HOME/out)
(>&2 echo "Done listing")

	dx-upload-all-outputs --parallel
	
    # Fill in your application code here.
    #
    # To report any recognized errors in the correct format in
    # $HOME/job_error.json and exit this script, you can use the
    # dx-jobutil-report-error utility as follows:
    #
    #   dx-jobutil-report-error "My error message"
    #
    # Note however that this entire bash script is executed with -e
    # when running in the cloud, so any line which returns a nonzero
    # exit code will prematurely exit the script; if no error was
    # reported in the job_error.json file, then the failure reason
    # will be AppInternalError with a generic error message.

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

#     for i in "${!OutTxt[@]}"; do
#         dx-jobutil-add-output OutTxt "${OutTxt[$i]}" --class=array:file
#     done
#     for i in "${!OutPng[@]}"; do
#         dx-jobutil-add-output OutPng "${OutPng[$i]}" --class=array:file
#     done
}
