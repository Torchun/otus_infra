[gitlab]
%{ for i,name in gitlab_names ~}
${ gitlab_names[i]} ansible_host=${gitlab_addrs[i]}
%{ endfor ~}
