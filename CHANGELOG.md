# Changelog — Aprendiz de Mercador

## 0.2.1 — Física e portas (outubro/2026)

**Colisão dos móveis.** Antes só as paredes do mapa tinham colisão, então dava para atravessar o balcão e os móveis. Agora o balcão vai de parede a parede (Marco fica do lado de dentro e o cliente do lado de fora), e as estantes de canto, a forja, o carrinho de carvão, os caixotes e a bancada do mestre vidreiro também bloqueiam a passagem. Os retângulos ficam em `FURNITURE_COLLIDERS`, no topo de `scripts/market.gd`.

**Portas interativas e o segundo andar.** A oficina do andar de cima agora é acessível:

- os dois arcos da loja ganharam portas de madeira que abrem e fecham (quadros da spritesheet `Doors_windows_animations` do CraftPix);
- na oficina, a escada da esquerda e a porta da direita levam de volta à loja;
- quem estiver perto de uma porta vê "[E] Subir para a oficina" ou "[E] Descer para a loja";
- a troca de andar tem animação da porta, escurecimento rápido da tela e a câmera passa a focar o andar atual.

Se um cliente chega enquanto Marco está lá em cima, aparece um aviso para descer ao balcão.

**Mestre vidreiro.** Quando Marco se aproxima dele na oficina, o mestre dá uma dica de matemática financeira. As dicas estão em `MASTER_TIPS`.

**Outros ajustes**

- A câmera ficou mais próxima (zoom 3,2) e mostra só o andar em que Marco está.
- Os textos dentro do cenário (balões, "[E]", dicas de porta) são desenhados em alta resolução e reduzidos, para não ficarem borrados com o zoom.
- O alcance para atender o cliente aumentou: dá para atender de qualquer ponto do balcão.

## 0.2.0 — Entregas da N2 (outubro/2026)

Esta versão implementa no jogo as entregas previstas no Artefato 04 (seção 3) e corrige problemas encontrados no Vertical Slice.

### Entregas previstas para a N2

**Expansão de Vilaforte.** Além do Bairro do Porto, o jogo agora tem a Rua dos Vidreiros (liberada na Loja Pequena) e a Praça da Coroa (liberada no Mercado Geral). Cada bairro tem produtos, preços e clientes próprios. O jogador escolhe onde abrir a loja toda manhã. Como a movimentação livre entre bairros saiu do escopo na N1, a troca de bairro é feita nessa tela da manhã, e o cenário ganha uma tonalidade própria em cada bairro.

**Narrativa da avó de Marco.** A Vó Celeste apresenta a loja no primeiro dia, manda uma "carta" a cada nível alcançado (com uma explicação curta do conteúdo novo), empresta 30 moedas quando o caixa fica negativo (para falar de saldo negativo) e aparece num epílogo depois de dez dias como Mercado Geral. Os textos ficam todos em `scripts/game_data.gd`.

**Clientes com personalidades distintas.** São seis clientes, e cada um muda a regra da negociação:

| Cliente | Perfil | Regra |
|---|---|---|
| Dona Ivone | Paciente | Aceita 2 de 3 critérios e dá uma segunda chance |
| Seu Bartolomeu | Pechincheiro | Sempre pede desconto em porcentagem |
| Lia, a mensageira | Apressada | Tem tempo limite e paga com moeda grande (troco) |
| Tomé, o aprendiz | Curioso | Fala em frações (1/2, 1/4, 1/5, 1/10) |
| Capitão Rui | Exigente | Só aceita com os 3 critérios certos e dá XP extra |
| Madame Odete | Nobre | Compra em quantidade e pergunta o lucro (ou prejuízo) |

Os clientes reaproveitam a spritesheet do CraftPix com troca de paleta por shader (`assets/shaders/palette_swap.gdshader`), então cada um tem cabelo, capa e camisa de cores diferentes sem precisar de arte nova.

**Apoio ao teste com o público real.** Cada resposta dada no balcão fica registrada. No menu, "Relatório do professor" mostra a taxa de acerto por conteúdo e exporta uma planilha CSV (separador `;`, abre direto no Excel em português) com aluno/grupo, cliente, pergunta, resposta dada, resposta correta, critérios, uso de dica e tempo de resposta.

**Versionamento em Git.** O projeto agora é um repositório Git com `.gitignore` para Godot 4 (a pasta `.godot/` não é versionada). O histórico começa com o estado da N1 e um segundo commit com estas mudanças.

### Core loop completo (Comprar → Negociar → Gerenciar)

- **Manhã no fornecedor:** o jogador compra o estoque do dia com o caixa disponível. A tela mostra a conta "Caixa − Compra = Sobra".
- **Dia de vendas:** de 3 a 5 clientes por dia, conforme o nível da loja. O cliente entra pela porta, para no balcão e só é atendido quando Marco chega perto e aperta E.
- **Entardecer:** resumo do dia com cada atendimento, receita, custo do que foi vendido, lucro do dia e progresso de XP.
- Não dá para vender o que não está no estoque. Recusar um pedido sem estoque é tratado como decisão certa.
- Save automático ao fim de cada dia e ao voltar ao menu. O menu mostra "Continuar".

### Desafios matemáticos

O desafio antes era sempre "preço × quantidade". Agora há cinco tipos, ligados ao perfil do cliente e ao nível da loja:

- Multiplicação (total da compra)
- Troco (subtração a partir da moeda entregue)
- Porcentagem (10%, 20%, 25%, 50%… com resultados decimais)
- Frações convertidas em desconto
- Lucro e prejuízo, com resultado negativo a partir do nível 3

Os critérios do GDD (Pedido, Preço e Cálculo) foram mantidos. Depois de cada venda aparece um checklist com ✔/✘ e a **resolução passo a passo** sempre que houve erro.

O botão **Dica da vó** substitui a dica antiga, que dava o número exato do desconto a ser digitado. A dica nova explica o caminho sem dar a resposta. Quem usa a dica perde o bônus de conta perfeita, e o uso fica registrado no relatório.

### Interface e arte

- Tema visual próprio (pergaminho, madeira e brasa), seguindo a paleta quente definida na direção de arte.
- Atkinson Hyperlegible nos textos e números, para que 5/S, 1/l e 0/O fiquem bem distintos; Pixelify Sans nos títulos.
- HUD com dia e período (manhã/tarde/entardecer), bairro, caixa, nível com barra de XP e fila de clientes.
- A câmera desliza para a esquerda quando o painel de negociação abre, para o balcão não ficar escondido.
- O mestre vidreiro (sprite `Master_Idle`) trabalha na oficina do andar de cima.
- Menu principal com a arte de fundo que estava sem uso no projeto.
- Opção de som liga/desliga, salva junto com o progresso.

### Correções

- O "[E]" e a dica "Pressione E" acendiam quando *qualquer* corpo entrava na área do cliente, inclusive as paredes do mapa. Agora só o jogador conta.
- A resposta "12,50" era lida como 12, porque `to_float()` ignora a vírgula. A leitura agora aceita vírgula, ponto, "R$" e sinal de menos.
- A moeda dos efeitos era o emoji 🪙, que não aparece em todo sistema. Foi trocada por um glifo desenhado com a fonte do jogo.
- A penalidade por erro dependia da quantidade escolhida pelo jogador (dava para perder muito dinheiro digitando 20). Agora o erro só faz perder a venda e o XP.
- Caixa, XP e dia ficavam dentro do painel de negociação e se perdiam ao sair da cena. Agora estão no autoload `GameState`.
- `game.gd` e `game.tscn` eram uma cópia antiga e não usada da lógica do `trade_panel.gd` e foram removidos. A imagem de fundo que só eles usavam virou o fundo do menu.

### Estrutura nova

```
scripts/
  game_data.gd          conteúdo: bairros, produtos, clientes, história, progressão
  game_state.gd         autoload: caixa, estoque, XP, save, relatório CSV
  challenge_generator.gd  pedidos e desafios matemáticos
  market.gd             ciclo do dia, HUD, câmera
  trade_panel.gd        negociação no balcão
  morning_panel.gd      compras da manhã
  day_summary_panel.gd  resumo do entardecer
  dialogue_box.gd       diálogos da Vó Celeste
  report_panel.gd       relatório do professor
  ui_theme.gd           tema visual
assets/
  fonts/                Atkinson Hyperlegible, Pixelify Sans, símbolos (licenças inclusas)
  shaders/palette_swap.gdshader
  art/menu_background.png
```
