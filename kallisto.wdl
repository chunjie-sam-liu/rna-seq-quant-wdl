## Version 1.0

workflow QUANTIFICATION {
  Array[File] bams
  File kallisto_index
  String output_dir

  Int nthread = 10


  Int machine_mem_gb = 30
  Int disk_space_gb = 100
  Boolean use_ssd = false
  String docker_image = "chunjiesamliu/rna-seq-quant-wdl"
  String docker_version = "latest"

  scatter (bam in bams) {
    call KALLISTO {
      input:
        bam = bam,
        kallisto_index = kallisto_index,

        nthread = nthread,
        machine_mem_gb = machine_mem_gb,
        disk_space_gb = disk_space_gb,
        use_ssd = use_ssd,
        docker_image = docker_image,
        docker_version = docker_version
    }
  }
  call GATHREQUANT {
    input:
      transcripts = KALLISTO.sf,
      output_dir = output_dir,
      nthread = nthread,
      machine_mem_gb = machine_mem_gb,
      disk_space_gb = disk_space_gb,
      use_ssd = use_ssd,
      docker_image = docker_image,
      docker_version = docker_version
  }

  output {
    File output_result = GATHREQUANT.output_result
  }

    meta {
    author: "Chun-Jie Liu"
    email : "chunjie.sam.liu@gmail.com"
    description: "WDL workflow on AnVIL for short RNA-seq quantification developed in Dr. Yi Xing's lab"
  }

}

task KALLISTO {
  File bam
  File kallisto_index

  Int nthread = 10

  Int machine_mem_gb = 16
  Int disk_space_gb = 100
  Boolean use_ssd = false
  String docker_image = "chunjiesamliu/rna-seq-quant-wdl"
  String docker_version = "latest"


  String stripped_bam = basename(bam, ".bam")

  command {
    samtools sort -@ ${nthread} -n -o ${stripped_bam}.sorted.bam ${bam}
    samtools fastq -@ ${nthread} \
      -1 ${stripped_bam}.1.fastq.gz \
      -2 ${stripped_bam}.2.fastq.gz \
      -0 /dev/null -s /dev/null \
      -n ${stripped_bam}.sorted.bam

    kallisto quant -i ${kallisto_index} \
      -t ${nthread} \
      -o ${stripped_bam} \
      ${stripped_bam}.1.fastq.gz ${stripped_bam}.2.fastq.gz

    mv ${stripped_bam}/abundance.tsv ${stripped_bam}/${stripped_bam}.abundance.tsv

  }

  runtime {
    docker: "${docker_image}:${docker_version}"
    memory: "${machine_mem_gb} GB"
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
    cpu: nthread
  }

  output {
    File sf = "${stripped_bam}/${stripped_bam}.abundance.tsv"
  }
}

task GATHREQUANT {
  Array[File] transcripts

  String output_dir

  Int nthread = 10

  Int machine_mem_gb = 16
  Int disk_space_gb = 100
  Boolean use_ssd = false
  String docker_image = "chunjiesamliu/rna-seq-quant-wdl"
  String docker_version = "latest"

  command {

    echo "Gathering results"
    mkdir -p ${output_dir}
    for file in ${sep=" " transcripts}; do cp $file ${output_dir}/; done

    tar -czvf ${output_dir}.tar.gz ${output_dir}

  }

  runtime {
    docker: "${docker_image}:${docker_version}"
    memory: "${machine_mem_gb} GB"
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
    cpu: nthread
  }

  output {
    File output_result = "${output_dir}.tar.gz"
  }
}