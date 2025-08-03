[dev]
%{ for ip in dev ~}
${ip}
%{ endfor ~}

[preprod]
%{ for ip in preprod ~}
${ip}
%{ endfor ~}

[prod]
%{ for ip in prod ~}
${ip}
%{ endfor ~}
