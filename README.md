# Aprendiz de Mercador

RPG econômico 2D em pixel art para ensinar matemática financeira (decimais, porcentagens, frações e números negativos) a estudantes de 10 a 16 anos. O jogador é Marco, aprendiz que herda a barraca da Vó Celeste em Vilaforte: compra mercadoria de manhã, atende clientes no balcão e acompanha o caixa ao fim do dia.

Projeto do PAC Extensionista — Engenharia de Software, Católica SC.

Equipe: Otavio Luiz Gelain, Enzo Viana, Kaian Dias, José Silveira.

O jogo ainda não tem uma tela de tutorial. Este arquivo é o guia para instalar, executar e jogar. O histórico de mudanças está em [CHANGELOG.md](CHANGELOG.md).

## Requisitos

| Item | Versão / detalhe |
|---|---|
| Sistema operacional | Windows 10 ou superior, macOS ou Linux |
| Programa | [Godot Engine 4.7](https://godotengine.org/download/archive/4.7-stable/) estável (4.7, 4.7.1 ou [4.7.2](https://godotengine.org/download/archive/4.7.2-stable/)), edição **Standard** (GDScript, sem .NET) |
| Outras dependências | Nenhuma. Fontes, arte e sons já estão no repositório |

O arquivo `project.godot` declara a feature `4.7`. Qualquer estável da linha 4.7 abre o projeto. A edição .NET não é necessária: todo o código está em GDScript.

Hardware modesto basta. A janela do jogo é 1280×720 e acompanha o tamanho da tela.

## Baixar o projeto

Pelo Git, em uma pasta de sua escolha:

```bash
git clone https://github.com/josesilveiraa07/aprendiz-de-mercador.git
cd aprendiz-de-mercador
```

Pelo navegador: abra o [repositório](https://github.com/josesilveiraa07/aprendiz-de-mercador), clique em **Code** e depois em **Download ZIP**. Extraia o arquivo. A pasta usada no Godot precisa conter o arquivo `project.godot` na raiz.

## Configurar o ambiente

Não há bibliotecas para instalar com npm, pip ou outro gerenciador. O único passo é ter o Godot 4.7 Standard disponível.

1. Baixe o Godot 4.7 Standard no site oficial. A [4.7](https://godotengine.org/download/archive/4.7-stable/) e a [4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) servem. Escolha o pacote **Standard** do seu sistema, e deixe de lado os pacotes marcados com .NET ou C#.
2. No Windows, extraia o `.zip` e execute o arquivo `Godot_v4.7-stable_win64.exe` (ou `Godot_v4.7.2-stable_win64.exe`, se baixou a 4.7.2).
3. No macOS, extraia o `.zip`, arraste o `Godot.app` para Aplicativos e execute-o. Se o sistema bloquear o app baixado, permita a abertura em Ajustes do Sistema, Privacidade e Segurança.
4. No Linux, extraia o `.zip` e execute o binário `Godot_v4.7-stable_linux.x86_64` (ou o equivalente `4.7.2`). Um pacote da distribuição também serve, desde que seja a linha 4.7.

Na primeira abertura, o Godot pode pedir o idioma e a pasta de projetos. Isso não altera o jogo.

## Executar

Pelo editor, que é o caminho previsto para esta entrega:

1. Abra o Godot 4.7. Na tela Project Manager, clique em **Import**.
2. Selecione o arquivo `project.godot` na raiz do projeto e confirme.
3. Espere a importação dos assets. Na primeira vez o editor gera a pasta `.godot/` e pode levar um minuto.
4. Com o projeto aberto, aperte **F5** ou o botão **Play** (triângulo no canto superior direito).
5. Se o editor perguntar a cena principal, escolha `scenes/main_menu.tscn`. Essa cena já está definida em `project.godot`, então a pergunta só aparece se a configuração tiver sido alterada.

Pela linha de comando, com o executável do Godot no `PATH` e o terminal na pasta do projeto:

```bash
godot --path .
```

No macOS, se o app estiver em Aplicativos:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Para abrir o editor em vez de ir direto ao jogo:

```bash
godot --path . --editor
```

Para encerrar, use **Sair** no menu ou feche a janela. O botão **Menu**, no canto da loja, grava o progresso e volta à tela inicial.

## Como começar uma partida

Na cena `scenes/main_menu.tscn`:

1. Clique em **Novo jogo**. Se já existir um save, o jogo pede confirmação: começar do zero apaga o progresso salvo. O relatório da sessão atual continua na memória até o programa ser fechado.
2. Leia o diálogo da Vó Celeste. Ela explica a barraca, o balcão e os três critérios da venda.
3. Avance cada fala com **E**, **Espaço**, **Enter** ou clique.
4. Na manhã, escolha o bairro, monte o estoque e clique em **Comprar e abrir a loja**.
5. Quando um cliente parar no balcão, caminhe até ele e aperte **E**.

**Continuar** aparece quando existe um save e mostra o dia e o nível da loja. O jogo grava sozinho ao fim de cada dia e ao voltar ao menu. O arquivo fica em `user://save.json`, na pasta de dados do Godot:

- Windows: `%APPDATA%\Godot\app_userdata\Aprendiz de Mercador\`
- Linux: `~/.local/share/godot/app_userdata/Aprendiz de Mercador/`
- macOS: `~/Library/Application Support/Godot/app_userdata/Aprendiz de Mercador/`

**Som: ligado / Som: desligado** alterna o áudio e grava a escolha junto com o progresso.

## Controles

| Tecla ou ação | O que faz |
|---|---|
| W A S D ou setas | Andar |
| Shift (segurar) | Correr |
| E | Atender o cliente, usar porta ou escada |
| E, Espaço, Enter ou clique | Avançar o diálogo |
| Enter | Confirmar a venda quando o cursor está no campo **Resposta** |
| Mouse | Menus, botões, produto, quantidade, desconto e resposta |
| Menu (botão na tela) | Salvar e voltar ao menu principal |

Não há controle de gamepad nesta versão.

## Objetivo, regras e progressão

Marco administra a loja para a avó. O objetivo é atender bem os clientes, manter o caixa e fazer a barraca crescer até o Mercado Geral. Cada dia tem três momentos.

### Manhã — comprar

A tela **Dia N · Manhã no fornecedor** mostra o caixa, o preço de compra, o preço de venda e o estoque. Use **+** e **−** para montar o pedido. A conta da tela é `Caixa − Compra = Sobra`. Só é possível comprar o que o caixa cobre. Dá para abrir o dia sem comprar nada.

O bairro escolhido define os produtos e os clientes daquele dia. Bairros ainda bloqueados aparecem com o nível exigido e o botão desativado.

| Bairro | Liberado em | O que treina |
|---|---|---|
| Bairro do Porto | Barraca Simples (início) | Compras pequenas, troco e descontos simples |
| Rua dos Vidreiros | Loja Pequena | Porcentagem e frações |
| Praça da Coroa | Mercado Geral | Pedidos grandes e lucro ou prejuízo |

O cenário visual é a oficina do vidreiro. Cada bairro muda a cor da cena. A troca de bairro acontece nessa tela da manhã.

Marco começa com 60 moedas, 4 maçãs e 4 pães. Maçã e pão são produtos do Porto; nos outros bairros os clientes pedem o catálogo local. Estoque não vendido continua no dia seguinte.

### Tarde — atender no balcão

Chegam 3 clientes na Barraca Simples, 4 na Loja Pequena e 5 no Mercado Geral, um por vez. O cliente entra, para no balcão e espera Marco chegar perto e apertar **E**. Se Marco estiver na oficina do segundo andar, um aviso pede para descer.

No painel, leia o pedido e a pergunta em **Desafio do balcão**. A tabela mostra o preço de venda por unidade e o estoque. Preencha:

- **Produto** e **Qtd.** — o que o cliente pediu.
- **Desconto** — a porcentagem pedida. Sem desconto, deixe 0%.
- **Resposta** — o número da pergunta. Aceita vírgula ou ponto nos centavos (`12,50` ou `12.50`), `R$` e sinal de menos (`-3`).

Depois clique em **Vender** ou aperte **Enter** no campo de resposta.

A venda é julgada por três critérios:

| Critério | Fica certo quando |
|---|---|
| Pedido | O produto e a quantidade são os do pedido |
| Preço | O desconto aplicado gera o total que o cliente deveria pagar |
| Cálculo | A resposta numérica está correta (tolerância de um centavo) |

O perfil do cliente diz quantos critérios ele exige, em geral 2 de 3. Capitão Rui exige os 3. Dona Ivone e Tomé dão uma segunda chance depois de um erro. Lia, a mensageira, tem cerca de 75 segundos; se o tempo acaba, ela vai embora.

| Cliente | Perfil | O que observar |
|---|---|---|
| Dona Ivone | Paciente | Aceita 2 de 3 e dá uma segunda chance |
| Seu Bartolomeu | Pechincheiro | Pede desconto em porcentagem |
| Lia, a mensageira | Apressada | Tem tempo limite e paga com moeda grande; a conta costuma ser o troco |
| Tomé, o aprendiz | Curioso | Fala em frações (1/2, 1/4, 1/5, 1/10). Aparece a partir da Loja Pequena |
| Capitão Rui | Exigente | Só aceita com os 3 critérios. Dá XP extra. Aparece a partir da Loja Pequena |
| Madame Odete | Nobre | Compra em quantidade e pergunta o lucro ou o prejuízo. Aparece no Mercado Geral |

**Dica da vó** explica o caminho da conta e não entrega o número pronto. Usar a dica tira o bônus de conta perfeita.

**Recusar** devolve o cliente sem venda. Se o estoque do produto pedido não cobre a quantidade, recusar é a decisão certa. Vender mais do que existe no estoque é bloqueado, e a tela pede para ajustar a quantidade ou recusar.

Uma venda aceita soma o valor recebido ao caixa e tira as unidades do estoque. Uma venda perdida, uma recusa ou o tempo esgotado não tiram dinheiro do caixa: perdem a venda e o XP daquele cliente. Depois do resultado, a tela mostra Pedido, Preço e Cálculo com ✔ ou ✘. Se houve erro, aparece a resolução passo a passo.

XP de uma venda aceita:

- 1 XP pela venda;
- +1 XP se o cliente dá bônus (Capitão Rui e Madame Odete);
- +1 XP se os 3 critérios estão certos e a dica não foi usada.

### Entardecer — fechar o dia

O resumo lista cada atendimento, a receita, o custo do que foi vendido, o lucro do dia, o gasto no fornecedor, o caixa e a barra de XP. Em seguida o próximo dia começa na manhã.

Se o caixa terminar negativo, a Vó Celeste explica o saldo devedor e empresta 30 moedas. A partida continua.

### Níveis da loja

| Nível | Nome | XP total para chegar | Clientes por dia |
|---|---|---|---|
| 1 | Barraca Simples | 0 (início) | 3 |
| 2 | Loja Pequena | 5 | 4 |
| 3 | Mercado Geral | 12 | 5 |

Ao subir de nível, a Vó Celeste manda uma carta com o conteúdo novo. No nível 2 entram porcentagem e frações e abre a Rua dos Vidreiros. No nível 3 abre a Praça da Coroa, e o prejuízo (número negativo) passa a ser uma resposta válida.

### Como a história termina

Depois de 10 dias já no Mercado Geral, a Vó Celeste aparece no epílogo e considera Marco pronto para cuidar da loja. Esse diálogo é o desfecho da história. Os dias seguintes continuam no mesmo ciclo, no nível máximo.

Não existe tela de derrota. Errar uma venda, recusar um cliente ou ficar no negativo não encerra a partida.

### Oficina do segundo andar

Pelas portas dos arcos, Marco sobe até a oficina do mestre vidreiro. Perto dele, o mestre solta uma dica de matemática financeira. Para voltar, use a escada da esquerda ou a porta da direita. O aviso na tela mostra **[E] Subir para a oficina** ou **[E] Descer para a loja**.

## Relatório para o professor

No menu, **Relatório do professor** mostra a taxa de acerto por conteúdo da sessão aberta. Dá para preencher o nome do aluno ou do grupo e exportar um CSV com separador `;`, que abre no Excel em português. Cada linha traz cliente, pergunta, resposta dada, resposta correta, critérios, uso de dica e tempo.

O botão de exportar grava em `user://relatorios` e abre essa pasta:

- Windows: `%APPDATA%\Godot\app_userdata\Aprendiz de Mercador\relatorios`
- Linux: `~/.local/share/godot/app_userdata/Aprendiz de Mercador\relatorios`
- macOS: `~/Library/Application Support/Godot/app_userdata/Aprendiz de Mercador/relatorios`

O relatório vive na memória da sessão. Feche o jogo só depois de exportar o CSV se quiser guardar as respostas. O save da partida não inclui essas tentativas nem o nome do aluno.

## Limitações desta versão

- Não há tutorial jogável separado. A orientação dentro do jogo é o diálogo inicial da Vó Celeste; o restante está neste guia.
- Não há executável pronto no repositório. A forma de jogar é abrir o projeto no Godot 4.7 e apertar F5. O arquivo `export_presets.cfg` tem um preset de Windows Desktop sem caminho de exportação preenchido.
- Os três bairros usam o mesmo mapa. A diferença visível é a cor da cena, e a escolha do bairro fica na tela da manhã.
- O estoque de um bairro permanece no inventário ao trocar de praça, mas os clientes só pedem os produtos do bairro aberto naquele dia.
- Não há game over. Caixa negativo recebe o empréstimo de 30 moedas e o dia seguinte começa normalmente.
- O epílogo, aos 10 dias de Mercado Geral, é um diálogo. A loja segue aberta nos dias seguintes.
- O relatório do professor e o nome do aluno ou grupo valem para a sessão atual. Exportar o CSV é o que preserva as respostas.
- Os controles são teclado e mouse.
- Os clientes reutilizam a mesma spritesheet, com cores trocadas por shader, para diferenciar cabelo, capa e camisa.

## Editando o conteúdo

Preços, produtos, XP por nível, clientes por dia, personalidades, falas e os diálogos da Vó Celeste ficam em `scripts/game_data.gd`. Dá para balancear o jogo por esse arquivo, sem alterar a lógica dos painéis.

## Créditos

- Arte: CraftPix — Glassblower's Workshop (licença gratuita craftpix.net).
- Fontes: Atkinson Hyperlegible (Braille Institute, OFL), Pixelify Sans (OFL), símbolos da DejaVu Sans. Veja `assets/fonts/LICENCAS.txt`.
- Motor: Godot Engine 4.7.
