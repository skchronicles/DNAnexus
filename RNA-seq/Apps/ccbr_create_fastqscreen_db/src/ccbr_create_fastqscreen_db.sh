#!/bin/bash
# ccbr_create_fastqscreen_db 0.0.1
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

build_bowtie2_index() {
        # myfunc only gets called when invoked by main (or by another
        # entry point)
		mkdir -p /data
		cd /data
        echo $input_fasta
        infa=$(dx describe "$input_fasta" --name)
        dx download "$input_fasta" -o $infa
        outtar=${infa%.*}.tar
        touch outtar
		(>&2 echo "DEBUG:Listing all files in root")
		(>&2 ls -larth)
		(>&2 echo "Done listing")
		dx-docker run -v /data/:/data kopardev/ccbr_bowties bowtie2-build $infa ${infa%.*}
		tar cvf $outtar *.bt2*
		(>&2 echo "DEBUG:Listing all files in root")
		(>&2 ls -larth)
		(>&2 echo "Done listing")
		echo "Uploading"
		OutTar=$(dx upload /data/$outtar --brief)
		dx-jobutil-add-output OutTar "$OutTar" --class=file
		echo "Done uploading"
}

main() {

    echo "Value of InFa: '${InFa[@]}'"
    echo "Value of DbName: '$DbName'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

mkdir -p /data
cd /data
cp /fastq_screen.conf .

(>&2 echo "DEBUG:Listing all files in root")
(>&2 ls -larth)
(>&2 echo "Done listing")
		
	subjobids=""
    for i in ${!InFa[@]}
    do
		process_job=$(dx-jobutil-new-job build_bowtie2_index -iinput_fasta="${InFa[$i]}")
		echo "Value of process_job: '$process_job'"
		subjobids="$subjobids $process_job"
    done
    count=0
    for i in $subjobids
    do
    	infa=$(dx describe "${InFa[$count]}" --name)
	    echo "Waiting for ",$i
		dx wait $i
		echo "Downloading tarfile"
		dx download $i:OutTar -o out_${count}.tar
		echo "Untaring"
		tar xvf out_${count}.tar
		rm -f out_${count}.tar
    	count=$((count+1))
    	echo -ne "DATABASE\t${infa%.*}\t/data/${infa%.*}\n" >> fastq_screen.conf
    done

(>&2 find /data)
    
(>&2 echo "DEBUG:Listing all files in root")
(>&2 ls -larth)
(>&2 echo "Done listing")
(>&2 tail fastq_screen.conf)

outtar=${DbName}.tar
tar cvf $outtar fastq_screen.conf *.bt2* 

# 	echo ${#InFa[@]}
# 	echo ${!InFa[@]}
# 	echo ${InFa[0]}
# 	echo ${InFa[1]}
	

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

    # The following line(s) use the dx command-line tool to upload your file
    # outputs after you have created them on the local file system.  It assumes
    # that you have used the output field name for the filename for each output,
    # but you can change that behavior to suit your needs.  Run "dx upload -h"
    # to see more options to set metadata.

    OutTar=$(dx upload /data/$outtar --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output OutTar "$OutTar" --class=file
}
