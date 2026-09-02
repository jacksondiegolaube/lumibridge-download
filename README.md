# LumiBridge

**Automação de luz entre o REAPER e o Lumikit Show, pela sua própria
Janela Personalizada.**

Você monta a Janela Personalizada no Lumikit Show como sempre. O
LumiBridge lê esse arquivo `.form`, redesenha a mesma tela dentro do
REAPER alinhada ao áudio, e grava na linha do tempo o que você clicar.
Terminada a criação, a automação é um item MIDI do seu projeto — e no
show **o LumiBridge não precisa estar aberto**: quem envia é o REAPER e
quem recebe é o Lumikit.

Serve para qualquer projeto em que a luz precise andar junto com o áudio:
show, teatro, cena, evento com trilha.

**[Página do produto](https://jacksondiegolaube.github.io/lumibridge-download/)** · **[Manual do usuário (PDF)](https://github.com/jacksondiegolaube/lumibridge-download/raw/main/LumiBridge-manual.pdf)** ·
**[Novidades](CHANGELOG.md)**

---

## Baixar

| | |
| --- | --- |
| **Instalador** — o caminho recomendado | [LumiBridge-instalador.exe](https://github.com/jacksondiegolaube/lumibridge-download/raw/main/LumiBridge-instalador.exe) |
| **Manual do usuário** — instalação, uso, atalhos e problemas comuns | [LumiBridge-manual.pdf](https://github.com/jacksondiegolaube/lumibridge-download/raw/main/LumiBridge-manual.pdf) |
| Arquivo único, para quem já tem o ReaImGui | [LumiBridge_standalone.lua](https://github.com/jacksondiegolaube/lumibridge-download/raw/main/LumiBridge_standalone.lua) |

Versão publicada: **1.0.4** — setembro/2026

O instalador baixa livremente, mas o programa **só abre com uma chave de
licença**. Veja *Ativar*, abaixo.

## Requisitos

| | |
| --- | --- |
| Sistema | Windows 10 ou 11 |
| REAPER | versão 6 ou mais nova, com a sua licença |
| Lumikit Show | com a Janela Personalizada exportada em `.form` |
| Porta MIDI | uma porta virtual entre os dois — o [loopMIDI](https://www.tobias-erichsen.de/software/loopmidi.html) resolve, e é grátis |
| Internet | só para baixar e para receber atualização; o programa funciona sem rede, inclusive na ativação |

## Instalar

1. Feche o REAPER.
2. Rode o `LumiBridge-instalador.exe` e siga.
3. Deixe marcada a opção que põe o botão na barra de ferramentas.
4. Abra o REAPER — o botão está lá. Pelo menu: *Actions › Show action
   list*, e procure por **LumiBridge**.

O instalador leva junto a biblioteca **ReaImGui**, necessária para a
janela, distribuída sob a licença LGPL-3.0 como arquivo separado e sem
modificação.

## Ativar

Na primeira abertura o programa mostra um código no formato
`LB-XXXX-XXXX`. Mande esse código a quem lhe vendeu o LumiBridge e digite
a chave que voltar.

A chave vale **só naquele computador**, para sempre, e nunca precisa de
internet. Trocou de máquina ou formatou? Peça outra.

## Primeiros ajustes

Na primeira vez, um assistente pede as quatro coisas de que o programa
precisa: o arquivo `.form`, a porta MIDI, a track onde gravar e a track
de referência da forma de onda. Ele volta quando você quiser, pelo botão
**Assistente** no topo das Configurações.

O manual explica cada passo, e traz uma lista do que conferir quando algo
não funciona.

## Atualizar

Em **Configurações › Sobre**, o botão *Procurar atualizações*. Ele mostra
o que mudou antes de instalar, confere o arquivo baixado e guarda a
versão anterior ao lado da nova.

## Sobre este repositório

Aqui fica só o que o cliente baixa — o instalador, o programa, o manual e
a página do produto. **O código-fonte é privado**; este repositório é a
distribuição, não o desenvolvimento.

## Independência

O LumiBridge é um projeto independente. Não há vínculo, sociedade nem
representação da Lumikit, da Cockos (REAPER) ou de qualquer outra
empresa. Você precisa ter as suas próprias licenças do REAPER e do
Lumikit Show — o LumiBridge não substitui, não modifica e não revende
nenhum dos dois.

REAPER é marca da Cockos Incorporated. Lumikit Show é marca da Lumikit.

## Suporte

Dúvidas, chaves e suporte pelo WhatsApp, com quem lhe vendeu.

Jackson Diego Laube
