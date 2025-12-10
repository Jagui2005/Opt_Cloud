Host bastion
    Hostname ${bastion_ip}
    User ec2-user
    IdentityFile ~/.ssh/bastion.pem
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

%{~ for i in range(num_instances) ~}
Host private-${i + 1}
    Hostname ${private_ips[i]}
    User ec2-user
    IdentityFile ~/.ssh/private-${i + 1}.pem
    ProxyJump bastion
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
%{~ endfor ~}
