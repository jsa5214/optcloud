Host ${bastion_name}
  HostName ${bastion_ip}
  User ec2-user
  IdentityFile ${bastion_key}
  StrictHostKeyChecking no

%{ for index, ip in private_ips ~}
Host private-${index + 1}
    HostName ${ip}
    User ec2-user
    IdentityFile ~/.ssh/private-${index + 1}.pem
    ProxyJump ${bastion_name}
    StrictHostKeyChecking no
%{ endfor ~}