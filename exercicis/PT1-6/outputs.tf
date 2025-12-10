output "bastion_public_ip" {
  description = "IP Pública Elàstica del Bastion Host."
  value       = aws_eip.bastion_eip.public_ip
}

output "private_instance_info" {
  description = "Informació sobre les instàncies privades (Nom: IP Privada)."
  value = {
    for i, inst in aws_instance.private :
    "private-${i + 1}" => inst.private_ip
  }
}

output "s3_key_backup_bucket" {
  description = "Nom del bucket S3 on es guarden les claus públiques."
  value       = aws_s3_bucket.key_backup.id
}

output "next_steps" {
  description = "Instruccions per connectar-se a la infraestructura."
  value = <<-EOT
    Instruccions Post-Desplegament:
    1. Executa: chmod +x setup_ssh.sh
    2. Executa: ./setup_ssh.sh

    Un cop executat l'script, podràs connectar-te:
    - ssh bastion (al Bastió directament)
    - ssh private-1 (a la instància privada 1 via ProxyJump)
    - ssh private-N (a la instància privada N via ProxyJump)
  EOT
}