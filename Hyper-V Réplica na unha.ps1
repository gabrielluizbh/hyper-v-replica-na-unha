# Script Hyper-V Replica - Hyper-V Réplica na "unha" - Créditos Gabriel Luiz - www.gabrielluiz.com ##


# Passo 1 ##

## Instalação da Função de Hyper-V e File Service, ambiente sem domínio - Windows Server 2016, 2019 ou Hyper-V 2016 ou 2019. ##


Install-WindowsFeature -Name Hyper-V, File-Services -IncludeManagementTools -restart # Instalação da Função de Hyper-V e File Service no Windows Server 2016 ou 2019.

Install-WindowsFeature -Name File-Services -IncludeManagementTools # Instalação da Função File Service no Hyper-V Server 2016 ou 2019.


# Observações:

# Estes comandos deve ser executado também no segundo servidor, no caso o servidor réplica.

# Ao final da instalação ambos servidores serão reinicializados.


## Passo 2 ##

## Renomear o hostname do servidor. ##

hostname # Obtenha o hostname do servidor. 

Rename-Computer -NewName "SR7" -DomainCredential Hostname\Administrador -Restart

Rename-Computer -NewName "SR8" -DomainCredential Hostname\Administrador -Restart

# Observações:

# Estes comandos deve ser executado também no segundo servidor, no caso o servidor réplica.

# Ao final da instalação ambos servidores serão reinicializados.


## Passo 3 ##

## Ingressar o servidor ao domínio. ##

add-computer -domainname contoso.local; restart-computer

# Observações:

# Este comando deve ser executado também no segundo servidor, no caso o servidor réplica.

# Ao final da instalação ambos servidores serão reinicializados.


## Passo 4 ##

## Criar as pastas para armazenamento do Hyper-V. ##

New-Item -Path c:\Hyper-V -ItemType directory

New-Item -Path "C:\Hyper-V\Virtual Hard Disks" -ItemType directory

New-Item -Path "C:\Hyper-V\Virtual Machines" -ItemType directory

New-Item -Path "C:\Hyper-V\Hyper-V Replica" -ItemType directory

# Observação:

# Este comando deve ser executado também no segundo servidor, no caso o servidor réplica.


## Passo 5 ##

## Alterar o local padrão de armazenamento das configurações das máquinas virtuais e VHDXs do Hyper-V. ##


Get-VMHost | fl # Obtenha as informações do host de Hyper-V.


Set-VMHost -VirtualHardDiskPath "C:\Hyper-V\Virtual Hard Disks" -VirtualMachinePath "C:\Hyper-V\Virtual Machines" -EnableEnhancedSessionMode $true


## Passo 5 ##

## Criar o adaptador de rede virtual. ##

Get-NetAdapter # Verificar os adptadores físicos.

New-VMSwitch -Name "Rede Externa" -NetAdapterName Ethernet # Criar o adaptador virtual


# Observação:

# Estes comandos deve ser executado também no segundo servidor, no caso o servidor réplica.


## Passo 6 ##

## Criação da máquina virtual. ##


New-VM VM -memory 2gb -Path 'C:\Hyper-V\Virtual Machines' -NewVHDPath "C:\Hyper-V\Virtual Hard Disks\VM.vhdx" -NewVHDSizeBytes 120gb -SwitchName "Rede Externa" -Generation 2 | Set-VMMemory -DynamicMemoryEnabled $false

Get-VM -Name VM | Set-VMProcessor -count 2


## Explicação do comando New-VM. ##

# Este comando cria uma máquina virtual com 2 GB de memória, cria uma VHDX de 120 GB de espaço de armazenamento, desabilitar o memória dinâmica. Máquina virtual armazenada em C:\Hyper-V\Virtual Machines e VHDX armazenado em C:\Hyper-V\Virtual Hard Disks.


## Explicação do comando Set-VMProcessor. ##

# Este comando altera o processador virtual da máquina virtual para 2 cores.



## Passo 7 ##

## Habilitando a réplica no Hyper-V em cada host do Hyper-V. ##


Set-VMReplicationServer -ReplicationEnabled $true -AllowedAuthenticationType Kerberos -ReplicationAllowedFromAnyServer $True -DefaultStorageLocation "C:\Hyper-V\Hyper-V Replica"

Set-VMReplicationServer -ReplicationEnabled $true -AllowedAuthenticationType Kerberos -ReplicationAllowedFromAnyServer $False # Sem certificado SSL, autenticação por Kerberos, devemos especificar o local de armazenamento, o servidor primário e o grupo de confiança.

New-VMReplicationAuthorizationEntry -AllowedPrimaryServer SR7.contoso.local -ReplicaStorageLocation "C:\Hyper-V\Hyper-V Replica" -TrustGroup Replicação # Especifica o servidor primário, armazenamento no local C:\Hyper-V\Virtual Hard Disks e o grupo de confiança.

New-VMReplicationAuthorizationEntry -AllowedPrimaryServer SR8.contoso.local -ReplicaStorageLocation "C:\Hyper-V\Hyper-V Replica" -TrustGroup Replicação # Especifica o servidor primário, armazenamento no local C:\Hyper-V\Virtual Hard Disks e o grupo de confiança.


## Explicação do comando Set-VMReplicationServer. ##


# Configura um host como um servidor de réplica. Habilitando o Hyper-V réplica usando a autenticação por Kerberos.


## Explicação do comando New-VMReplicationAuthorizationEntry. ##

# Cria uma nova entrada de autorização que permite que um ou mais servidores primários repliquem dados para um servidor de réplica especificado.


# Observações:

# Todos os comandos devem ser executado em cada servidor de Hyper-V Réplica que deseja receber a réplica.

# O comando New-VMReplicationAuthorizationEntry só pode ser executando quando o comando -ReplicationAllowedFromAnyServer estiver com o valor $false.


## Passo 8 ##

# Liberação das portas do firewall dos servidores primário e réplica do Hyper-V Réplica. ##


Enable-NetfirewallRule -DisplayName "Ouvinte de HTTP da Réplica do Hyper-V (TCP-In)" # Português

Enable-NetFirewallRule -DisplayName "Ouvinte HTTPS da Réplica do Hyper-V (TCP-In)" # Português

Enable-NetfirewallRule -DisplayName "Hyper-V Replica HTTP Listener (TCP-In)" # Inglês

Enable-NetFirewallRule -DisplayName "Hyper-V Replica HTTPS Listener (TCP-In)" # Inglês


# Observação:

# Este comando deve ser executado em cada servidor de Hyper-V Réplica.


## Passo 9 ##

## Permitir a replicação de uma máquina virtual. ##


Enable-VMReplication -AuthenticationType Kerberos -ReplicaServerName SR8.contoso.local -ReplicaServerPort 80 -VMName VM -AutoResynchronizeEnabled $True -AutoResynchronizeIntervalEnd 23:59:59 -AutoResynchronizeIntervalStart 00:00:00 -CompressionEnabled $True -RecoveryHistory 24 -ReplicationFrequencySec 30 -VSSSnapshotFrequencyHour 12


## Explicação do comando Enable-VMReplication. ##

# Este comando tem muitos parametros que podem ser modifcados de acordo com o seu cenário, temos alguns paramentros importantes são eles:

# -AutoResynchronizeEnabled - Sãos três modificações que podemos fazer, igualmenta a da GUI:

# Manual. -AutoResynchronizeEnabled 0 

# Automática. -AutoResynchronizeEnabled $True completa com os comandos: -AutoResynchronizeIntervalEnd 23:59:59 -AutoResynchronizeIntervalStart 00:00:00

# Agendada. -AutoResynchronizeEnabled $True completa com os comandos: -AutoResynchronizeIntervalEnd 18:00:00 -AutoResynchronizeIntervalStart 07:00:00

# -CompressionEnabled $True - HAbilita a compressão dos dados para trasmissão.

# -RecoveryHistory - Especifica se é necessário armazenar pontos de recuperação adicionais da máquina virtual. Armazenar mais do que o ponto de recuperação mais recente da máquina virtual, permite recuperar um ponto anterior no tempo. No entanto, armazenar pontos de recuperação adicionais requer mais espaço de armazenamento e processamento. Você pode configurar até 24 pontos de recuperação para serem armazenados.

# -ReplicationFrequencySec - Especifica a frequência, em segundos, na qual o servidor primário envia as alterações da máquina virtual para o servidor de réplica. Podemos colocar os seguinte valores 30 - para 30 segundos, 600 - para 5 minutos e 900 para 15 minutos, igualmente a GUI.

# -VSSSnapshotFrequencyHour - Especifica a frequência, em horas, na qual o Serviço de Cópias de Sombra de Volume (VSS) executa um backup de captura instantânea das máquinas virtuais. Valor máximo de 12 horas.

# -VMName - Especifica qual máquina virtual deve receber a configuração da replicação definidar. Se caso quiser habilitar em todas as máquinas virtuais do host altere o valor para *.


## Passo 10 ##

## Realizar a replicação inicial da máquina virtual. ##

Start-VMInitialReplication -VMName VM # Realizar a replicação inicial de uma máquina virtual especifica imediatamente.

Start-VMInitialReplication -VMName VM -InitialReplicationStartTime "06/04/2019 05:37 PM" # Realizar a replicação inicial da máquina virtual na data e hora especificado.

Start-VMInitialReplication * # Realizar a replicação inicial de todas as máquinas virtual do host de Hyper-V imediatamente.

Start-VMInitialReplication -VMName VM -DestinationPath D:\ # Neste exemplo as máquinas virtuais são exportadas para um HD externo e sua replicação inicial feita através.


# Observação:

# o comando Start-VMInitialReplication * -DestinationPath D:\ deve ser executado no servidor primário.



## Passo 11 ##

## Realizar importação da replicação inicial. ##


Import-VMInitialReplication VM D:\VM_FC1E46AC-3F42-4256-BE1B-068A11FB35CB # Realizar importação da replicação inicial que estar armazenado no diretório d:\VM_FC1E46AC-3F42-4256-BE1B-068A11FB35CB.



## Explicação do comando

# O cmdlet Import-VMInitialReplication importa arquivos da replicação inicial em um servidor de réplica. Ele conclui a replicação inicial de uma máquina virtual quando um HD externo é usado como a origem dos arquivos para a replicação inicial.


## Passo 12 ##

## Realizar o failover planejado. ##


## Passo 1 ##

Stop-VM –VMName VM –ComputerName SR7.contoso.local # Primeiro você deve desligar a máquina virtual.


## Passo 2 ##


Start-VMFailover –VMName VM –ComputerName SR7.contoso.local –Prepare # O primeiro comando se prepara para o failover planejado de uma máquina virtual primária denominada VM, replicando todas as alterações pendentes.

Start-VMFailover -VMName VM -computername SR8.contoso.local  # O segundo comando deve ser executado no servidor réplica, neste caso o SR8. Inicia o failover no servidor réplica.


Start-VM -Name VM # Inicia a máquina virtual no servidor réplica que foi invertido, neste caso SR8.


Stop-VM -Name VM # Para execução da máquina virtual em execução no servidor SR8.


Set-VMReplication -Reverse -VMName VM -computername SR8.contoso.local # Inverte a replicação da máquina virtual.


# Observação

# Também é possivel realizar um failover planejado escolhedo o ponto de restauração como o seguintes comandos:


Get-VMSnapshot -VMName VM # Verifique os pontos de restauração disponiveis para máquina virtual especifica.


Start-VMFailover -Prepare -VMName VM | Get-VMSnapshot VM -Name "VM - (11/04/2019 - 21:56:00)" # Executa o failover planejado escolhendo o ponto de restauração especificado.



## Passo 13 ##

## Parar o failover. ##

Stop-VMFailover VM # Para o failover da máquina virtual especifica.

Stop-VMFailover * # Para o failover de todas máquinas virtuais.


## Passo 14 ##

## Realizar o failover teste. ##

Start-VMFailover VM -AsTest # Realiza o failover teste da máquina virtual.

Get-VMSnapshot -VMName VM # Verifique os pontos de restauração disponiveis para máquina virtual especifica.

Get-VMSnapshot -VMName * # Verifique os pontos de restauração disponiveis para todas as máquinas virtuais.

Get-VMSnapshot VM -Name "VM - Standard Replica - (28/03/2019 - 22:34:10)" | Start-VMFailover -AsTest # Inicia um failover de uma máquina virtual chamada VM com o ponto de recuperação VM - Standard Replica - (28/03/2019 - 22:34:10).

Stop-VMFailover VM # Para o teste de failover.


## Passo 15 ##

## Realizar o failover não planejado. ##


Start-VMFailover VM # Realiza o failover da máquina virtual especificada.

Start-VM -Name VM # Inicia a máquina virtual no servidor réplica que foi invertido, neste caso SR8.

Stop-VM -Name VM # Para execução da máquina virtual em execução no servidor SR8.


## Observações:

# Quando se tem um destratre em um ambiente de produção ao cancelar o failover você perderas alterações feitas na máquina virtual após o failover, O RECOMENDADO É NUNCA CANCELAR O FAILOVER E SIM REMOVER A REPLICAÇÃO EM AMBOS OS LADOS.

# Se os servidores estão conectadados em uma rede WAN o recomendado e inverter a 

# Para cancelar a replicação execute o seguinte comando em abos os servidor, primário e servidor réplica.

Remove-VMReplication VM # Este comando remove a replicação da máquina virtual especificada.

Remove-VMReplication * # Este comando remove a replicação de todas as máquinas virtuais.


# Deleta a máquina virtual.

Remove-VM -Name VM


# Faça a exclusão da pastas C:\Hyper-V\Hyper-V Replica\Hyper-V Replica


rmdir 'C:\Hyper-V\Hyper-V Replica\Hyper-V Replica'


# Execute novamente a habilitação da replicação da máquina virtual.


Enable-VMReplication -AuthenticationType Kerberos -ReplicaServerName SR8.contoso.local -ReplicaServerPort 80 -VMName VM -AutoResynchronizeEnabled $True -AutoResynchronizeIntervalEnd 23:59:59 -AutoResynchronizeIntervalStart 00:00:00 -CompressionEnabled $True -RecoveryHistory 24 -ReplicationFrequencySec 30 -VSSSnapshotFrequencyHour 12


# Após habiliar a replicação da máquina virtual execute novamente os comandos do passo 10.

## Passo 10 ##

## Realizar a replicação inicial da máquina virtual ##

# Pronto, após um failover em produção a sua máquina virtual vai estar salva com todos as alterações feitas após o failover.


## Passo 16 ##

## Gerenciar a replicação. ##


Suspend-VMReplication VM # Suspende a replicação de uma máquina virtual.

Suspend-VMReplication * # Suspende a replicação de todas as máquinas virtuais.

Resume-VMReplication VM # Retorna a replicação de uma máquina virtual.
Resume-VMReplication * # Retorna a replicação de todas as máquinas virtuais.

Resume-VMReplication VM -Resynchronize # Este exemplo ressincroniza a replicação da máquina virtual VM.

Resume-VMReplication VM -Resynchronize -ResynchronizeStartTime "31/03/2019 07:11 PM" # Este exemplo agenda a ressincronização de replicação para a máquina virtual VM para iniciar às 19:11 de 31 de Março de 2019.

Reset-VMReplicationStatistics VM # Redefine as estatísticas de replicação para a máquina virtual VM.

Get-VMReplication | Reset-VMReplicationStatistics # Redefine as estatísticas de replicação de todas as máquinas virtuais ativadas para replicação no host Hyper-V local.

Get-VMReplication # Este exemplo obtém as configurações de replicação de todas as máquinas virtuais habilitadas para replicação no host Hyper-V local.

Get-VMReplication VM # Este exemplo obtém as configurações de replicação de uma máquina virtual chamada VM.

Get-VMReplication -ReplicaServerName SR8.contoso.local # Este exemplo obtém as configurações de replicação de todas as máquinas virtuais replicando para o servidor SR8.contoso.local.

Get-VMReplication -ReplicationState Replicating # Este exemplo obtém as configurações de replicação de todas as máquinas virtuais no estado Replicando.

Get-VMReplication -ReplicationState Suspended # Este exemplo obtém as configurações de replicação de todas as máquinas virtuais no estado Suspenso.

Set-VMReplicationServer -MonitoringInterval "12:00:00" -MonitoringStartTime "17:00:00" # Este comando configura o servidor de réplica com um intervalo de monitoramento de 12 horas, iniciando às 17:00 horas.

Set-VMReplicationServer -MonitoringInterval "12:00:00" -MonitoringStartTime "23:18:00" # Este comando configura o servidor de réplica com um intervalo de monitoramento de 12 horas, iniciando às 17:00 horas.