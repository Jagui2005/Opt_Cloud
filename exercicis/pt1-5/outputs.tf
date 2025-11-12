output "instance_details" {
  description = "Detalls de les instàncies EC2 creades, incloent ID, IP pública i IP privada."
  value = {
    public_instances = [
      for instance in aws_instance.public_instances : {
        id         = instance.id
        public_ip  = instance.public_ip
        private_ip = instance.private_ip
      }
    ]
    private_instances = [
      for instance in aws_instance.private_instances : {
        id         = instance.id
        public_ip  = instance.public_ip
        private_ip = instance.private_ip
      }
    ]
  }
}

output "s3_bucket_name" {
  description = "El nom del bucket S3 creat. Es mostra només si la variable 'create_s3_bucket' és true."
  value       = var.create_s3_bucket ? aws_s3_bucket.conditional_bucket[0].id : "El bucket S3 no s'ha creat."
}