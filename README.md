# Cluster de Alta Disponibilidade com EC2 na AWS usando Application Load Balancer e Auto Scaling Group

![Cluster de Alta Disponibilidade](./imagens/ALB_ASG_EC2.jpg)

## Configuração da Rede

Primeiramente, criamfoi criados todos os recursos de rede, incluindo uma VPC, duas sub-redes em zonas de disponibilidade diferentes, tabelas de rotas e um Internet Gateway para acesso à internet.

![Configuração de Rede](./imagens/rede.JPG)

## Auto Scaling Group 

Em seguida foi criado um template com definições padrões para instâncias EC2, com a execução de um script padrão para a instalação do Apache, usando a AMI mais recente do Amazon Linux.

Foi criado também o Auto Scaling Group, que inicia pelo menos duas instâncias EC2 e no máximo de quatro. Também configuramos uma verificação de integridade (Health Check) das instâncias EC2, que as substituirá se não estiverem íntegras.

![Auto Scaling Group](./imagens/ASG.JPG)

## Application Load Balancer

 Criado os recursos relacionados ao Application Load Balancer (ALB). Primeiro, foi criado o ALB (aws_lb), que é responsável pelo balanceamento de carga. Em seguida, foi realizado a criação o target group (aws_lb_target_group) para controlar o roteamento de solicitações de tráfego para as instâncias de destino. Por último, definimos o listener (aws_lb_listener) para direcionar o tráfego de entrada do balanceador de carga para os grupos de destino (target groups) ou instâncias de destino EC2.

![Application Load Balancer](./imagens/ALB.JPG)

## Camada de Segurança

Na camada de segurança foi criado dois grupos de segurança (Security Groups). Um deles restringe o tráfego para somente HTTPS e HTTP no Application Load Balancer, enquanto o outro permite que as instâncias EC2 recebam requisições apenas do Load Balancer.

Security Group para o Load Balancer:

![Security Group para o Load Balancer](./imagens/SG_ALB.JPG)

Security Group para as Instâncias EC2:

![Security Group para as Instâncias EC2](./imagens/SG_EC2.JPG)

## Evidências de Funcionamento

Funcionamento do site em um host EC2
![Funcionamento do site em um host EC2](./imagens/Evidencia01.JPG)

Funcionamento do site em outro host EC2
![Funcionamento do site em outro host EC2](./imagens/Evidencia02.JPG)

Todos os recursos criados
![Todos os recursos criados](./imagens/Evidencia03.JPG)

Instancias em Auta disponibilidade
![Instancias em Auta disponibilidade](./imagens/Evidencia04.JPG)
