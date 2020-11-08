output "dns_ip_pass" {
  value = [
    for i in aws_route53_record.dns_record :
    "${index(aws_route53_record.dns_record, i)}: ${i.name} ${hcloud_server.OPS09[index(aws_route53_record.dns_record, i)].ipv4_address} ${random_string.new_password[index(aws_route53_record.dns_record, i)].result}"
  ]
}
