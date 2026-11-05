# Aprendiz de Mercador

RPG econômico 2D em pixel art para ensinar matemática financeira (decimais, porcentagens, frações e números negativos) a estudantes de 10 a 16 anos. Projeto do PAC Extensionista — Engenharia de Software, Católica SC.

Equipe: Otavio Luiz Gelain, Enzo Viana, Kaian Dias, José Silveira.

## Como rodar

1. Instale o **Godot 4.6** (versão Standard, sem .NET).
2. No Project Manager, clique em **Import** e selecione o `project.godot` desta pasta.
3. Aguarde a importação dos assets e aperte **F5**. A cena inicial é `scenes/main_menu.tscn`.

## Controles

| Tecla | Ação |
|---|---|
| W A S D / setas | Andar |
| Shift (segurar) | Correr |
| E | Atender o cliente / usar portas e escada / continuar |
| Enter | Vender (no campo de resposta) |
| E / Espaço / clique | Avançar diálogo |

## Como o dia funciona

1. **Manhã:** escolha o bairro e compre o estoque no fornecedor.
2. **Balcão:** os clientes chegam um por vez. Chegue perto, aperte E e preencha produto, quantidade, desconto e a resposta do desafio. A venda é avaliada por três critérios: Pedido, Preço e Cálculo. Quantos precisam estar certos depende do cliente.
3. **Entardecer:** veja receita, custo, lucro e XP. O jogo salva sozinho.

Pelas portas dos arcos, Marco sobe até a oficina do mestre vidreiro no segundo andar. Para voltar, é só usar a escada ou a porta de lá.

A loja sobe de nível com XP (Barraca Simples → Loja Pequena → Mercado Geral), e cada nível libera um bairro novo.

## Relatório para o professor

No menu, **Relatório do professor** mostra a taxa de acerto por conteúdo e exporta uma planilha CSV com todas as respostas da sessão. Os arquivos ficam na pasta de dados do Godot (`user://relatorios`), que o botão de exportar abre automaticamente.

- Windows: `%APPDATA%\Godot\app_userdata\Aprendiz de Mercador\relatorios`
- Linux: `~/.local/share/godot/app_userdata/Aprendiz de Mercador/relatorios`
- macOS: `~/Library/Application Support/Godot/app_userdata/Aprendiz de Mercador/relatorios`

## Editando o conteúdo

Todo o conteúdo de design fica em `scripts/game_data.gd`: preços e produtos de cada bairro, XP por nível, clientes por dia, personalidades e falas dos clientes, e os diálogos da Vó Celeste. Dá para balancear o jogo sem mexer na lógica.

## Créditos

- Arte: CraftPix — Glassblower's Workshop (licença gratuita craftpix.net).
- Fontes: Atkinson Hyperlegible (Braille Institute, OFL), Pixelify Sans (OFL), símbolos da DejaVu Sans. Veja `assets/fonts/LICENCAS.txt`.
- Motor: Godot Engine 4.6.

Histórico de mudanças em [CHANGELOG.md](CHANGELOG.md).
