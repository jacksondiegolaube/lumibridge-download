-- LumiBridge 1.0.1  (compilado em 2026-09-02 13:04)
--[==[--------------------------------------------------------------------
  LumiBridge — versão de arquivo único
  GERADO AUTOMATICAMENTE por tools/build_standalone.lua. Não edite à mão.

  Instalação:
    1. Instale a extensão ReaImGui pelo ReaPack.
    2. Actions > Show action list > New action > Load ReaScript...
    3. Selecione este arquivo. Não precisa de nenhuma pasta ao lado.
----------------------------------------------------------------------]==]

-- ============================ core.version
package.preload["core.version"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/version.lua

  Identidade do programa: versão, autor, nome.

  Por que existe (e por que é um módulo, não uma constante solta em
  ui/window.lua):
    A versão precisa ser lida pela interface (a aba Sobre) e é o tipo de
    dado que qualquer parte do programa pode querer — um registro de
    diagnóstico, uma mensagem de erro. Como é Lua puro, sem reaper nem
    ImGui, mora em core/ pela mesma regra do resto: ver PROJECT_CONTEXT.md.

  NUMERAÇÃO — MAIOR.MENOR.CORREÇÃO (versionamento semântico)

    MAIOR      muda quando algo grande muda de forma: o formato do que
               é gravado, a arquitetura, um jeito de trabalhar diferente.
    MENOR      recurso novo que não quebra nada do que já existia.
    CORREÇÃO   conserto de defeito, sem recurso novo.

    Antes disto o projeto contava V101, V102... V108 — um número só,
    que não dizia se a mudança tinha sido um ajuste de cor ou uma
    reescrita. O histórico daquela contagem está no CHANGELOG.md; a
    contagem semântica começa em 1.0.0, marcando um programa já pronto
    e em uso em show.

  O NÚMERO NÃO ESTÁ MAIS NO NOME DO ARQUIVO, de propósito. Enquanto
  esteve (LumiBridge_standalone_V108.lua), cada versão nova era um
  arquivo novo: a ação registrada no REAPER continuava apontando pro
  arquivo velho, e o usuário acumulava ações mortas na lista — chegaram
  a coexistir uma V99 e uma V108 apontando pra pastas diferentes. Com
  nome fixo, registra-se a ação uma vez e atualizar é só substituir o
  arquivo.
------------------------------------------------------------------------]]

local Version = {}

Version.MAIOR    = 1
Version.MENOR    = 0
Version.CORRECAO = 1

Version.NOME  = 'LumiBridge'
Version.AUTOR = 'Jackson Diego Laube'

--- Quando este arquivo foi gerado.
--
--  POR QUE UM CARIMBO E NÃO SÓ O NÚMERO DE VERSÃO. O número muda quando
--  eu decido mudá-lo; o carimbo muda a cada compilação. É a diferença
--  entre "que versão é essa" e "é esta a compilação que acabei de
--  receber" — e essa segunda pergunta já custou uma rodada inteira de
--  conversa, com um defeito corrigido de um lado e a tela do outro lado
--  ainda mostrando o defeito.
--
--  tools/build_standalone.lua reescreve esta linha ao gerar o arquivo
--  único. Rodando pelos módulos soltos, ela fica em 'desenvolvimento',
--  que é a verdade: ali não há compilação nenhuma.
Version.COMPILACAO = "2026-09-02 13:04"

--- Onde o programa procura por versão nova.
--
--  Um arquivo de texto de três linhas, publicado por você:
--
--      1.0.1
--      https://.../LumiBridge_standalone.lua
--      O que mudou, numa frase.
--
--  Texto puro e não JSON de propósito: você vai editar isso à mão, com
--  pressa, no meio de uma correção. Três linhas não dão para errar.
--
--  DEIXE VAZIO para desligar a procura por atualizações. É o padrão
--  enquanto o repositório público não existir — um botão que sempre
--  falha é pior que botão nenhum.
--
--  O REPOSITÓRIO APONTADO AQUI É PÚBLICO, e é só o que o cliente baixa.
--  O repositório do CÓDIGO tem o segredo da licença e os geradores de
--  chave: publicá-lo entrega a fábrica de chaves junto com o programa.
Version.MANIFESTO = 'https://raw.githubusercontent.com/jacksondiegolaube/lumibridge-download/main/atualizacao.txt'

--- Compara "1.2.3" com "1.10.0" pelo número, não pelo texto.
--
--  Como texto, "1.10.0" < "1.2.3" — a atualização mais nova pareceria
--  velha e ninguém receberia a correção. É o tipo de erro que só aparece
--  na décima versão menor, meses depois.
--  @return true se `outra` for mais nova que a instalada
function Version.maisNovaQue(outra, instalada)
  local function partes(v)
    local a, b, c = tostring(v or ''):match('(%d+)%.(%d+)%.(%d+)')
    return tonumber(a), tonumber(b), tonumber(c)
  end
  local a1, b1, c1 = partes(outra)
  local a2, b2, c2 = partes(instalada or Version.numero())
  if not a1 or not a2 then return false end
  if a1 ~= a2 then return a1 > a2 end
  if b1 ~= b2 then return b1 > b2 end
  return c1 > c2
end

--- "1.0.0"
function Version.numero()
  return ('%d.%d.%d'):format(Version.MAIOR, Version.MENOR, Version.CORRECAO)
end

--- "LumiBridge 1.0.0"
function Version.completa()
  return ('%s %s'):format(Version.NOME, Version.numero())
end

--- "1.0.0 · 2026-09-01 14:32" — o que identifica uma compilação.
function Version.completaComCompilacao()
  return ('%s · %s'):format(Version.numero(),
                            Version.COMPILACAO or 'desconhecida')
end

return Version
]=], "@core/version.lua"))(...)
end

-- ============================ core.xml
package.preload["core.xml"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/xml.lua

  Leitor XML mínimo, especializado em documentos "só de atributos"
  como o .form do Lumikit.

  REGRA DE ARQUITETURA:
    Este módulo é Lua puro. Nunca pode referenciar `reaper` nem `ImGui`.
    Isso permite testá-lo no terminal, fora do REAPER.

  Por que não usar uma biblioteca pronta:
    O .form não tem namespaces, não tem nós de texto e não tem CDATA.
    Todo o conteúdo vive em atributos. Um leitor especializado cabe em
    ~100 linhas, não adiciona dependência e é mais rápido do que um
    parser genérico num arquivo de 800 KB.

  Estratégia:
    Varredura por ponteiro (sem loop caractere a caractere).
    Os valores de atributo são lidos como "[^\"]*", o que torna o parser
    imune a caracteres '<' e '>' crus dentro de valores — importante,
    porque o .form guarda um script Pascal inteiro num atributo.
------------------------------------------------------------------------]]

local XML = {}

local NAMED = { lt = '<', gt = '>', amp = '&', quot = '"', apos = "'" }

--- Converte entidades XML para texto. Sai cedo se não houver '&'.
local function unescape(s)
  if not s:find('&', 1, true) then return s end
  s = s:gsub('&#[xX](%x+);', function(h) return utf8.char(tonumber(h, 16)) end)
  s = s:gsub('&#(%d+);',     function(d) return utf8.char(tonumber(d, 10)) end)
  s = s:gsub('&(%a+);',      function(n) return NAMED[n] or ('&' .. n .. ';') end)
  return s
end

--- Analisa um documento XML.
--  @param text string  conteúdo bruto do arquivo
--  @return table|nil   nó raiz { tag, attrs, children }, ou nil + mensagem
function XML.parse(text)
  if type(text) ~= 'string' then return nil, 'conteúdo inválido' end

  -- BOM UTF-8
  if text:sub(1, 3) == '\239\187\191' then text = text:sub(4) end

  local root, stack = nil, {}
  local pos, len = 1, #text

  while pos <= len do
    local lt = text:find('<', pos, true)
    if not lt then break end

    local c = text:sub(lt + 1, lt + 1)

    if c == '?' or c == '!' then
      -- declaração, comentário ou doctype: ignora até '>'
      local gt = text:find('>', lt + 1, true)
      if not gt then break end
      pos = gt + 1

    elseif c == '/' then
      -- tag de fechamento
      local gt = text:find('>', lt + 1, true)
      if not gt then break end
      stack[#stack] = nil
      pos = gt + 1

    else
      local _, name_end, name = text:find('^([%w_:%.%-]+)', lt + 1)
      if not name then
        pos = lt + 1
      else
        local p = name_end + 1
        local attrs = {}

        while true do
          local _, attr_end, key, val =
            text:find('^%s*([%w_:%.%-]+)%s*=%s*"([^"]*)"', p)
          if not attr_end then break end
          attrs[key] = unescape(val)
          p = attr_end + 1
        end

        local _, close_end, slash = text:find('^%s*(/?)>', p)
        if not close_end then
          pos = p  -- tag malformada: avança e segue
        else
          local node = { tag = name, attrs = attrs, children = {} }
          local parent = stack[#stack]

          if parent then
            parent.children[#parent.children + 1] = node
          elseif not root then
            root = node
          end

          if slash ~= '/' then stack[#stack + 1] = node end
          pos = close_end + 1
        end
      end
    end
  end

  if not root then return nil, 'nenhum elemento raiz encontrado' end
  return root
end

--- Lê e analisa um arquivo do disco.
function XML.parseFile(path)
  local f, err = io.open(path, 'rb')
  if not f then return nil, ('não foi possível abrir: %s'):format(err or path) end
  local content = f:read('a')
  f:close()
  return XML.parse(content)
end

--- Retorna os filhos diretos com a tag informada.
function XML.children(node, tag)
  local out = {}
  if not node then return out end
  for i = 1, #node.children do
    local child = node.children[i]
    if child.tag == tag then out[#out + 1] = child end
  end
  return out
end

--- Retorna o primeiro filho direto com a tag informada, ou nil.
function XML.child(node, tag)
  if not node then return nil end
  for i = 1, #node.children do
    if node.children[i].tag == tag then return node.children[i] end
  end
  return nil
end

--- Navega um caminho de tags: XML.path(root, 'controls', 'extraFunctions')
function XML.path(node, ...)
  for _, tag in ipairs({ ... }) do
    node = XML.child(node, tag)
    if not node then return nil end
  end
  return node
end

return XML
]=], "@core/xml.lua"))(...)
end

-- ============================ core.model
package.preload["core.model"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/model.lua

  O MODELO INTERNO. Esta é a fronteira do projeto.

  REGRA DE ARQUITETURA:
    Lua puro. Nunca pode referenciar `reaper` nem `ImGui`.
    Também não pode conter nada específico do formato .form.

  Por que este módulo existe:
    O parser converte .form -> Modelo. O renderer lê Modelo -> tela.
    Nenhum dos dois conhece o outro. Consequências práticas:

      - Se o Lumikit mudar o formato de exportação, só o parser muda.
      - Se quisermos outro renderer (ou suportar outro formato de
        controlador), só essa ponta muda.
      - O parser pode ser testado no terminal, sem abrir o REAPER.

  Vocabulário:
    Layout   : uma janela inteira (1382x744, seus elementos, seu mapa MIDI)
    Element  : algo desenhável na tela, já com tudo resolvido
    Command  : uma mensagem MIDI a enviar quando o elemento for acionado

  IMPORTANTE: os elementos saem do parser já RESOLVIDOS. O renderer
  recebe "botão em x=352 y=48, escrito WAVE ALT, cinza #878787, envia
  nota 30". Ele nunca precisa saber que isso veio do cruzamento de três
  tabelas do XML.
------------------------------------------------------------------------]]

local Model = {}

--- Tipos de elemento reconhecidos pelo renderer.
Model.KIND = {
  SHAPE  = 'shape',   -- retângulo de fundo (painéis)
  LABEL  = 'label',   -- texto estático (títulos de painel, F1..F12)
  BUTTON = 'button',  -- botão de função
  FADER  = 'fader',   -- fader vertical
  PAGE   = 'page',    -- botão de navegação de página
}

--- Tipos de mensagem MIDI.
Model.MIDI = {
  NOTE_ON = 'note_on',
  NOTE_OFF = 'note_off',
  CC = 'cc',
  RAW = 'raw',
}

-- ---------------------------------------------------------------- Layout

--- Cria um Layout vazio.
function Model.newLayout()
  return {
    name       = '',
    width      = 0,      -- tamanho DECLARADO no arquivo (metadado)
    height     = 0,
    contentWidth  = 0,   -- limites REAIS do conteúdo (o renderer usa estes)
    contentHeight = 0,
    midiPort   = 1,      -- índice da entrada MIDI configurada no controlador
    snapToGrid = true,
    pages      = {},     -- { { name = 'Page 1', onlyOne = false }, ... }
    elements   = {},     -- em ordem de empilhamento (fundo -> frente)
    rules      = {},     -- regras de grupo; ver core/rules.lua
    source     = nil,    -- caminho do arquivo de origem, informativo
    stats      = {},     -- contagens, preenchidas pelo parser
  }
end

--- Anexa um elemento ao final da pilha de desenho.
function Model.addElement(layout, element)
  layout.elements[#layout.elements + 1] = element
  return element
end

-- --------------------------------------------------------------- Cores

--- Cria uma cor. Componentes 0..255.
function Model.color(r, g, b)
  return { r = r or 0, g = g or 0, b = b or 0 }
end

--- Clareia (amount > 0) ou escurece (amount < 0) uma cor. amount em -1..1.
function Model.shade(c, amount)
  local function mix(v)
    if amount >= 0 then return v + (255 - v) * amount end
    return v * (1 + amount)
  end
  return Model.color(
    math.floor(mix(c.r) + 0.5),
    math.floor(mix(c.g) + 0.5),
    math.floor(mix(c.b) + 0.5)
  )
end

--- Luminância perceptual 0..1. Usada para escolher texto claro ou escuro.
function Model.luminance(c)
  return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) / 255
end

-- ------------------------------------------------------------ Comandos

--- Cria um comando MIDI. Guardado como bytes crus para não perder nada.
function Model.command(status, data1, data2)
  local kind = Model.MIDI.RAW
  local high = status & 0xF0
  if high == 0x90 then
    kind = (data2 == 0) and Model.MIDI.NOTE_OFF or Model.MIDI.NOTE_ON
  elseif high == 0x80 then
    kind = Model.MIDI.NOTE_OFF
  elseif high == 0xB0 then
    kind = Model.MIDI.CC
  end
  return {
    kind    = kind,
    status  = status,
    data1   = data1,
    data2   = data2,
    channel = (status & 0x0F) + 1,  -- 1..16, como aparece no REAPER
  }
end

--- Descrição legível de um comando, para logs e para a UI de depuração.
function Model.describeCommand(cmd)
  if not cmd then return '—' end
  if cmd.kind == Model.MIDI.NOTE_ON then
    return ('Note On  ch%d  nota %d  vel %d'):format(cmd.channel, cmd.data1, cmd.data2)
  elseif cmd.kind == Model.MIDI.NOTE_OFF then
    return ('Note Off ch%d  nota %d'):format(cmd.channel, cmd.data1)
  elseif cmd.kind == Model.MIDI.CC then
    return ('CC ch%d  cc %d  valor %d'):format(cmd.channel, cmd.data1, cmd.data2)
  end
  return ('Raw %02X %02X %02X'):format(cmd.status, cmd.data1, cmd.data2)
end

-- -------------------------------------------------------------- Consultas

--- Retorna todos os elementos de um dado tipo.
function Model.byKind(layout, kind)
  local out = {}
  for i = 1, #layout.elements do
    if layout.elements[i].kind == kind then out[#out + 1] = layout.elements[i] end
  end
  return out
end

--- Elementos que podem ser acionados (têm ao menos um comando MIDI).
function Model.triggerable(layout)
  local out = {}
  for i = 1, #layout.elements do
    local e = layout.elements[i]
    if e.commands and #e.commands > 0 then out[#out + 1] = e end
  end
  return out
end

--- Resumo textual do layout. Usado pelo teste de terminal e pela UI.
function Model.summary(layout)
  local counts = {}
  for i = 1, #layout.elements do
    local k = layout.elements[i].kind
    counts[k] = (counts[k] or 0) + 1
  end
  return {
    name      = layout.name,
    size      = ('%dx%d'):format(layout.contentWidth, layout.contentHeight),
    declared  = ('%dx%d'):format(layout.width, layout.height),
    elements  = #layout.elements,
    shapes    = counts[Model.KIND.SHAPE]  or 0,
    labels    = counts[Model.KIND.LABEL]  or 0,
    buttons   = counts[Model.KIND.BUTTON] or 0,
    faders    = counts[Model.KIND.FADER]  or 0,
    pages     = counts[Model.KIND.PAGE]   or 0,
    mapped    = #Model.triggerable(layout),
  }
end

return Model
]=], "@core/model.lua"))(...)
end

-- ============================ core.form_parser
package.preload["core.form_parser"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/form_parser.lua

  Converte um arquivo .form do Lumikit Show no Modelo interno.
  Este é o ÚNICO módulo do projeto que conhece o formato .form.

  REGRA DE ARQUITETURA:
    Lua puro. Nunca pode referenciar `reaper` nem `ImGui`.

  ------------------------------------------------------------------
  O FORMATO, RESUMIDO
  ------------------------------------------------------------------
  XML de atributos, UTF-8 com BOM, sem quebras de linha. Nomes de
  classe no estilo Delphi/Lazarus (TFreeForm*).

  O layout nasce do cruzamento de TRÊS listas independentes:

    <control>        onde  -> left, top, width, height, tag,
                             extraFunctionIndex
    <extraFunction>  o quê -> name, uicolor, image (ícone), comportamento
    <actionmidi1>    como  -> data/data1/data2 = mensagem MIDI que o
                             Lumikit ESCUTA para acionar o controle

  Chaves de ligação:
    control.extraFunctionIndex  ->  índice na lista de extraFunction (base 0)
    actionmidi1.index           ->  control.tag

  A terceira lista é o que torna o LumiBridge possível: ela já contém,
  pronta, a mensagem que precisamos ENVIAR para acionar cada botão.

  Detalhes verificados no arquivo de referência (Tropical.form):
    - Cores em TColor do Delphi: inteiro decimal 0x00BBGGRR
      (byte baixo = vermelho). Ver bgrToColor().
    - Ícones: bitmap 32x32 em paleta indexada por letra (1024 chars).
      Guardados crus no modelo; a renderização entra numa etapa futura.
    - activeWhilePressed="false" em 188 de 189 funções: os botões são
      TOGGLE (um clique liga, outro desliga), não momentâneos.
    - A ordem dos <control> no XML É a ordem de empilhamento.
    - Índices de extraFunction são base 0.
------------------------------------------------------------------------]]

local here = (...):match('^(.*)%.[^%.]*$') or ''
local XML   = require(here .. '.xml')
local Model = require(here .. '.model')

local FormParser = {}

FormParser.VERSION = '2.0'

-- ------------------------------------------------------------------------
-- AUDITORIA DE ATRIBUTOS
--
-- Todo atributo que o parser encontra e não reconhece é REGISTRADO, nunca
-- descartado em silêncio. Isso existe por um motivo concreto: o Lumikit
-- oferece vários tipos de grupo, e se um .form futuro usar um tipo cujo
-- nome de atributo não está mapeado aqui, o comportamento sumiria sem
-- deixar rastro — o usuário veria "o grupo não funciona" e não haveria
-- nada no código apontando para a causa.
--
-- Com a auditoria, um atributo desconhecido aparece na barra da janela e
-- no teste de terminal, dizendo exatamente qual é o nome que falta mapear.
-- ------------------------------------------------------------------------

--- Atributos de <rule>: nome no XML -> papel no modelo.
--
--  Os quatro primeiros grupos são LISTAS DE PERTENCIMENTO, cada uma com
--  numeração própria. Os demais são AÇÕES que um controle dispara.
--
--  Aceitamos grafias alternativas para as ações "ao desativar": o campo
--  "ativar grupo ao desativar" não aparece no arquivo de referência, então
--  o nome exato dele no Lumikit não pôde ser confirmado. Mapeamos as
--  variantes plausíveis; qualquer outra cai na auditoria e vira uma linha
--  de código, não uma investigação.
local RULE_FIELDS = {
  groupId               = 'exclusiveId',       -- grupo apenas um ativo
  groupOnId             = 'onMemberId',        -- grupo ativar
  groupOffId            = 'offMemberId',       -- grupo desativar
  groupTurnOnId         = 'turnOnId',          -- ativar grupo ao ativar
  groupTurnOffId        = 'turnOffId',         -- desativar grupo ao ativar
  groupTurnOnWhenOffId  = 'turnOnWhenOffId',   -- ativar grupo ao desativar
  groupTurnOffWhenOffId = 'turnOffWhenOffId',  -- desativar grupo ao desativar
  groupOnWhenOffId      = 'turnOnWhenOffId',   -- grafia alternativa
  groupOffWhenOffId     = 'turnOffWhenOffId',  -- grafia alternativa
}

--- Atributos conhecidos que não são grupos, para a auditoria não os acusar.
local RULE_IGNORED = { tag = true, page = true }

-- ------------------------------------------------------------- utilidades

local function num(v, default)
  return tonumber(v) or default or 0
end

local function bool(v, default)
  if v == 'true' then return true end
  if v == 'false' then return false end
  return default
end

local function trim(s)
  if not s then return '' end
  return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

--- Converte TColor do Delphi (0x00BBGGRR) para cor do modelo.
--  O byte MENOS significativo é o vermelho — o inverso do RGB usual.
local function bgrToColor(v)
  local n = math.floor(num(v, 0))
  return Model.color(n & 0xFF, (n >> 8) & 0xFF, (n >> 16) & 0xFF)
end

--- Ícone cru: bitmap quadrado em paleta indexada por letra.
--  Retorna nil se ausente ou se o tamanho não for um quadrado perfeito.
local function parseIcon(data)
  if not data or data == '' then return nil end
  local n = #data
  local side = math.floor(math.sqrt(n) + 0.5)
  if side * side ~= n then return nil end
  return { width = side, height = side, pixels = data }
end

-- ------------------------------------------------------------ seções

--- Atributos reconhecidos de <extraFunction>.
local KNOWN_FUNCTION_ATTRS = {
  name = true, uicolor = true, image = true, imageOff = true,
  functionType = true, activeWhilePressed = true, solo = true,
  offonblackout = true, aOff = true, aOffValue = true,
  fadeIn = true, fadeOut = true, executionStep = true,
  changeFadePriority = true,
}

--- Atributos reconhecidos de <control>, por classe.
local KNOWN_CONTROL_ATTRS = {
  class = true, left = true, top = true, width = true, height = true,
  tag = true, extraFunctionIndex = true, caption = true, color = true,
  fontColor = true, fontName = true, fontSize = true, mode = true,
  image = true, imageOff = true, gotoPage = true, executePage0 = true,
  MIDIFeedbackData = true, MIDIFeedbackData1 = true,
  MIDIFeedbackData2On = true, MIDIFeedbackData2Off = true,
  MIDIFeedbackColorTable = true,
}

--- Lê <extraFunctions>: a biblioteca de funções (nome, cor, ícone, modo).
--  Indexada por número base 0, como no atributo extraFunctionIndex.
local function readFunctions(root, audit)
  local out = {}
  local container = XML.path(root, 'controls', 'extraFunctions')
  if not container then return out end

  local list = XML.children(container, 'extraFunction')
  for i = 1, #list do
    local node = list[i]
    local a = node.attrs
    for name in pairs(a) do
      if not KNOWN_FUNCTION_ATTRS[name] then audit('extraFunction', name) end
    end
    out[i - 1] = {
      index      = i - 1,
      name       = trim(a.name),
      color      = bgrToColor(a.uicolor),
      icon       = parseIcon(a.image),
      iconOff    = parseIcon(a.imageOff),
      type       = num(a.functionType),
      -- activeWhilePressed=true significa momentâneo; false significa toggle.
      momentary  = bool(a.activeWhilePressed, false),
      solo       = bool(a.solo, false),
      -- "grupo de execução": passos encadeados de uma mesma função.
      -- Lido e preservado; não afeta o desenho nem o envio MIDI.
      executionStep = tonumber(a.executionStep),
      fadeIn        = tonumber(a.fadeIn),
      fadeOut       = tonumber(a.fadeOut),
    }
  end
  return out
end

--- Lê <actionmidi1>: o mapa de entrada MIDI do Lumikit.
--  Retorna uma tabela indexada por control.tag -> lista de comandos.
local function readMidiMap(root)
  local map = {}
  local list = XML.children(root, 'actionmidi1')
  for i = 1, #list do
    local a = list[i].attrs
    local tag = num(a.index, -1)
    if tag >= 0 then
      local cmd = Model.command(num(a.data), num(a.data1), num(a.data2))
      cmd.page      = num(a.page, 1)
      cmd.actionType = num(a.type)
      cmd.usedata2  = bool(a.usedata2, false)
      map[tag] = map[tag] or {}
      map[tag][#map[tag] + 1] = cmd
    end
  end
  return map
end

--- Lê <rules>: as regras de grupo (exclusividade e ações em cadeia).
--  Um mesmo tag pode aparecer em várias regras, portanto pertencer a
--  vários grupos. A lista é devolvida crua; core/rules.lua monta os
--  índices de consulta.
local function readRules(root, audit)
  local out = {}
  local container = XML.path(root, 'controls', 'rules')
  if not container then return out end

  -- Grupo 0 e ausência significam a mesma coisa: sem grupo.
  local function group(v)
    local n = tonumber(v)
    if not n or n == 0 then return nil end
    return n
  end

  for _, node in ipairs(XML.children(container, 'rule')) do
    local a = node.attrs
    local tag = tonumber(a.tag)
    if tag then
      local rule = { tag = tag, page = num(a.page, 0) }

      for name, value in pairs(a) do
        local field = RULE_FIELDS[name]
        if field then
          -- Um campo pode receber de mais de uma grafia; a primeira
          -- com valor vence, e as demais não sobrescrevem com nil.
          rule[field] = rule[field] or group(value)
        elseif not RULE_IGNORED[name] then
          audit('rule', name)
        end
      end

      out[#out + 1] = rule
    end
  end
  return out
end

--- Lê <keyboard>: atalhos de teclado -> control.tag.
local function readKeyboard(root)
  local map = {}
  local container = XML.path(root, 'controls', 'keyboard')
  if not container then return map end
  for _, node in ipairs(XML.children(container, 'key')) do
    local tag = num(node.attrs.tag, -1)
    if tag >= 0 then map[tag] = num(node.attrs.id) end
  end
  return map
end

-- ------------------------------------------------------- construção dos elementos

--- Base comum: geometria e identidade.
--  Elementos com largura ou altura zero são marcados como ocultos.
--  Isso não é defensivo: o arquivo de referência contém um label
--  "STROBO" com height="0", resto de uma edição antiga no Lumikit,
--  que o próprio Lumikit não desenha. Reproduzimos esse comportamento.
local function baseElement(kind, a)
  local e = {
    kind = kind,
    x    = num(a.left),
    y    = num(a.top),
    w    = num(a.width),
    h    = num(a.height),
    tag  = tonumber(a.tag),
  }
  e.hidden = (e.w <= 0 or e.h <= 0)
  return e
end

--- Constrói um elemento a partir de um <control>, já resolvendo os joins.
local function buildElement(node, functions, midiMap, keyMap)
  local a = node.attrs
  local class = a.class

  if class == 'TFreeFormShape' then
    local e = baseElement(Model.KIND.SHAPE, a)
    e.color = bgrToColor(a.color)
    return e
  end

  if class == 'TFreeFormLabel' then
    local e = baseElement(Model.KIND.LABEL, a)
    e.text      = a.caption or ''
    e.fontName  = a.fontName or 'Arial'
    e.fontSize  = num(a.fontSize, 12)
    e.textColor = bgrToColor(a.fontColor)
    -- mode: alinhamento. Só o valor 0 aparece no arquivo de referência e,
    -- comparado com a captura de tela, corresponde a centralizado.
    e.align     = (num(a.mode) == 0) and 'center' or 'left'
    return e
  end

  if class == 'TFreeFormButtonEF' or class == 'TFreeFormFaderEF' then
    local isFader = (class == 'TFreeFormFaderEF')
    local e = baseElement(isFader and Model.KIND.FADER or Model.KIND.BUTTON, a)

    local fn = functions[num(a.extraFunctionIndex, -1)]
    if fn then
      e.text      = fn.name
      e.color     = fn.color
      e.icon      = fn.icon
      e.iconOff   = fn.iconOff
      e.momentary = fn.momentary
      e.functionIndex = fn.index
    else
      -- Referência quebrada: preserva o elemento em vez de descartá-lo,
      -- para que a falha fique visível na tela e não silenciosa.
      e.text  = '?'
      e.color = Model.color(90, 40, 40)
      e.orphan = true
    end

    e.textColor = Model.color(255, 255, 255)
    e.commands  = midiMap[e.tag] or {}
    e.key       = keyMap[e.tag]
    return e
  end

  if class == 'TFreeFormButtonPage' then
    local e = baseElement(Model.KIND.PAGE, a)
    e.text      = trim(a.caption)
    e.color     = bgrToColor(a.color)
    e.textColor = Model.color(255, 255, 255)
    e.icon      = parseIcon(a.image)
    e.gotoPage  = num(a.gotoPage)
    e.commands  = midiMap[e.tag] or {}
    e.key       = keyMap[e.tag]
    return e
  end

  -- Classe desconhecida: registra para diagnóstico, não interrompe a carga.
  return nil, class
end

-- --------------------------------------------------------------- API

--- Converte um documento XML já analisado no Modelo.
function FormParser.fromDocument(root)
  if not root or root.tag ~= 'form' then
    return nil, 'raiz <form> não encontrada: este não parece ser um arquivo .form'
  end

  local a = root.attrs
  local layout = Model.newLayout()
  layout.name       = a.freeFormName or 'Sem nome'
  layout.width      = num(a.width, 800)
  layout.height     = num(a.height, 600)
  layout.midiPort   = num(a.freeFormMIDIId, 1)
  layout.snapToGrid = bool(a.freeFormSnapToGrid, true)

  -- Identifica a TELA (não o arquivo): o Lumikit grava este hash de
  -- novo, idêntico, toda vez que exporta o mesmo layout. É a chave
  -- usada para guardar preferências por tela — como os atalhos F1-F12
  -- do LumiBridge — sem depender do caminho do arquivo, que muda se o
  -- usuário mover ou renomear o .form.
  layout.freeFormHash = a.freeFormHash or ''

  local pagesNode = XML.path(root, 'controls', 'extraFunctions', 'pages')
  for _, p in ipairs(XML.children(pagesNode, 'page')) do
    layout.pages[#layout.pages + 1] = {
      name    = p.attrs.name or ('Página %d'):format(#layout.pages + 1),
      onlyOne = bool(p.attrs.onlyOne, false),
    }
  end
  if #layout.pages == 0 then
    layout.pages[1] = { name = 'Página 1', onlyOne = false }
  end

  -- Coletor da auditoria: acumula nomes de atributos não reconhecidos.
  local unknownAttrs = {}
  local function audit(where, name)
    local key = where .. '.' .. name
    unknownAttrs[key] = (unknownAttrs[key] or 0) + 1
  end

  local functions = readFunctions(root, audit)
  local midiMap   = readMidiMap(root)
  local keyMap    = readKeyboard(root)
  layout.rules    = readRules(root, audit)

  local unknown = {}
  local controlsNode = XML.child(root, 'controls')
  -- A ordem no XML é a ordem de empilhamento: preservar é obrigatório.
  for _, node in ipairs(XML.children(controlsNode, 'control')) do
    for name in pairs(node.attrs) do
      if not KNOWN_CONTROL_ATTRS[name] then audit('control', name) end
    end
    local element, unknownClass = buildElement(node, functions, midiMap, keyMap)
    if element then
      Model.addElement(layout, element)
    elseif unknownClass then
      unknown[unknownClass] = (unknown[unknownClass] or 0) + 1
    end
  end

  -- Limites reais do conteúdo.
  --
  -- Os atributos width/height do <form> descrevem a JANELA, e no arquivo
  -- de referência eles não batem com o conteúdo: declara 1382x744, mas os
  -- controles vão de fato até 1440x680 (a coluna AUTO e o F12 passam da
  -- largura declarada; sobram 64px mortos na altura). A captura de tela
  -- confirma que o Lumikit desenha pelos limites do conteúdo.
  --
  -- Portanto: o renderer usa contentWidth/contentHeight. Os valores
  -- declarados ficam guardados, mas não mandam no desenho.
  local maxX, maxY = 0, 0
  local minX, minY = math.huge, math.huge
  for _, e in ipairs(layout.elements) do
    if not e.hidden then
      if e.x + e.w > maxX then maxX = e.x + e.w end
      if e.y + e.h > maxY then maxY = e.y + e.h end
      if e.x < minX then minX = e.x end
      if e.y < minY then minY = e.y end
    end
  end
  layout.contentWidth  = maxX
  layout.contentHeight = maxY

  -- A MARGEM QUE O PRÓPRIO ARQUIVO DEIXA, à esquerda e no topo.
  --
  -- Quem desenha usa isto para deixar a MESMA folga à direita e embaixo.
  -- O conteúdo termina exatamente no último pixel do último controle, e
  -- encaixar por ele deixava o painel com margem de um lado e nada do
  -- outro — visivelmente torto numa janela cheia.
  --
  -- Isto NÃO mexe na geometria do .form: nenhum controle muda de lugar,
  -- só se reserva espaço em volta. A regra "o .form é desenhado como
  -- está" continua valendo.
  layout.marginX = (minX < math.huge) and minX or 0
  layout.marginY = (minY < math.huge) and minY or 0

  -- Controles COBERTOS por outro controle desenhado depois.
  --
  -- Isso é uma TÉCNICA DELIBERADA do usuário, não resíduo de edição:
  -- empilhar um controle atrás de outro é a forma de manter um botão
  -- acessível só por tecla de atalho, sem ocupar espaço na tela. No
  -- arquivo de referência, BPM está atrás de PAUSA e RELEASE ALL está
  -- atrás de BACKOUT, e ambos são usados pelas teclas B e R.
  --
  -- Consequências, e a distinção importa:
  --   - NÃO é desenhado e NÃO recebe clique. O Lumikit desenha em ordem
  --     de documento, então o clique pertence a quem está por cima.
  --   - O ATALHO DE TECLADO continua valendo. É justamente para isso
  --     que o controle foi escondido.
  --
  -- Só marcamos cobertura TOTAL. Sobreposição parcial continua interativa.
  local function interactive(e)
    return e.kind == Model.KIND.BUTTON
        or e.kind == Model.KIND.FADER
        or e.kind == Model.KIND.PAGE
  end

  local n = #layout.elements
  for i = 1, n do
    local a = layout.elements[i]
    if not a.hidden and interactive(a) then
      for j = i + 1, n do
        local b = layout.elements[j]
        if not b.hidden and interactive(b)
           and b.x <= a.x and b.y <= a.y
           and b.x + b.w >= a.x + a.w
           and b.y + b.h >= a.y + a.h then
          a.covered = true
          a.coveredBy = b.text
          break
        end
      end
    end
  end

  local functionCount = 0
  for _ in pairs(functions) do functionCount = functionCount + 1 end

  local mappedTags = 0
  for _ in pairs(midiMap) do mappedTags = mappedTags + 1 end

  layout.stats = {
    rules         = #layout.rules,
    functions     = functionCount,
    midiEntries   = mappedTags,
    keyboardKeys  = (function() local n = 0 for _ in pairs(keyMap) do n = n + 1 end return n end)(),
    unknownClasses = unknown,
    unknownAttrs   = unknownAttrs,
  }

  return layout
end

--- Converte texto .form no Modelo.
function FormParser.parse(text)
  local root, err = XML.parse(text)
  if not root then return nil, err end
  return FormParser.fromDocument(root)
end

--- Carrega um arquivo .form do disco e devolve o Modelo.
function FormParser.parseFile(path)
  local f, err = io.open(path, 'rb')
  if not f then
    return nil, ('não foi possível abrir o arquivo: %s'):format(err or path)
  end
  local content = f:read('a')
  f:close()

  local layout, perr = FormParser.parse(content)
  if not layout then return nil, perr end
  layout.source = path
  return layout
end

return FormParser
]=], "@core/form_parser.lua"))(...)
end

-- ============================ core.rules
package.preload["core.rules"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/rules.lua

  Motor de regras de grupo do Lumikit.

  REGRA DE ARQUITETURA:
    Lua puro. Nunca pode referenciar `reaper` nem `ImGui`.
    É uma máquina de estados: recebe o estado atual e o controle
    acionado, devolve o novo estado. Isso a torna trivialmente testável.

  ------------------------------------------------------------------
  O QUE ESTE MÓDULO NÃO FAZ  (importante)
  ------------------------------------------------------------------
  Ele NÃO gera MIDI. Nem um byte.

  O Lumikit já aplica essas regras sozinho quando recebe o Note On:
  se você aciona VERM PURO, é o Lumikit que desliga BRANCO PURO. Se o
  LumiBridge também enviasse o desligamento, a regra seria aplicada
  duas vezes e o resultado ficaria errado.

  O papel deste módulo é só manter o estado VISUAL do LumiBridge em
  sincronia com o que o Lumikit fez. Isso não é cosmético: se a tela
  mostrar um botão apagado que na verdade está aceso, o próximo clique
  vai fazer o oposto do que você espera.

  ------------------------------------------------------------------
  OS TIPOS DE GRUPO
  ------------------------------------------------------------------
  A Janela Personalizada do Lumikit oferece vários tipos de grupo, e
  cada tipo tem sua PRÓPRIA numeração. O "grupo apenas um ativo 2" e o
  "grupo ativar 2" são grupos diferentes, que por acaso têm o mesmo
  número. Tratar tudo como uma numeração só produz efeitos absurdos —
  por exemplo, "ativar grupo 2" acenderia os 28 movimentos de uma vez,
  sendo que eles são justamente exclusivos entre si.

  Portanto existem três listas de pertencimento independentes:

    groupId    "grupo apenas um ativo"  exclusividade dentro do grupo
    groupOnId  "grupo ativar"           alvo dos comandos de ligar
    groupOffId "grupo desativar"        alvo dos comandos de desligar

  E quatro ações, que um controle dispara sobre as listas acima:

    groupTurnOnId          ao ligar,    liga o "grupo ativar" N
    groupTurnOffId         ao ligar,    desliga o "grupo desativar" N
    groupTurnOnWhenOffId   ao desligar, liga o "grupo ativar" N
    groupTurnOffWhenOffId  ao desligar, desliga o "grupo desativar" N

  Um mesmo controle pode ter várias regras e portanto participar de
  vários grupos ao mesmo tempo.

  ------------------------------------------------------------------
  A PÁGINA FAZ PARTE DA IDENTIDADE DO GRUPO
  ------------------------------------------------------------------
  Cada <rule> traz um atributo `page`, e o número do grupo só vale
  DENTRO da sua página. O "grupo 4 da página 0" e o "grupo 4 da página
  1" são grupos diferentes.

  Ignorar isso misturava painéis inteiros. No arquivo de referência, o
  grupo 4 da página 0 são os 12 gobos do BEAM EFFECTS, e o grupo 4 da
  página 1 são 8 movimentos do PAN/TILT. Tratados como um só, escolher
  um gobo apagava os movimentos — que é exatamente o sintoma relatado.

  Com a página no cálculo, cada painel fica com o seu grupo: 28 no
  PAN/TILT, 28 no MASTER COLORS, 12 nos gobos, e assim por diante.

  Exemplos reais do arquivo de referência:
    CENA A..G  groupTurnOnId=22   e os 5 masters têm groupOnId=22
               -> acionar uma cena sobe os masters
    FLYOUT     groupTurnOffId=3   e os 4 BEAM têm groupOffId=3
               -> acionar FLYOUT apaga os efeitos de beam

  O campo groupTurnOnWhenOffId não aparece neste arquivo, mas o tipo
  existe no Lumikit. É lido assim mesmo, para que um .form futuro que
  o use funcione sem alteração de código.

  ------------------------------------------------------------------
  PONTO A VALIDAR NA TELA
  ------------------------------------------------------------------
  A separação por tipo é o que a terminologia do Lumikit indica, e é a
  única leitura que não gera absurdos. O caso mais fácil de conferir é
  o FLYOUT: ao acioná-lo, devem apagar os quatro botões de BEAM do
  DIMMER EFFECTS, e as cores devem continuar como estavam.
------------------------------------------------------------------------]]

local Rules = {}

-- --------------------------------------------------------------- índice

--- Monta os índices de consulta a partir das regras cruas do layout.
--  Feito uma vez ao carregar o arquivo, não a cada clique.
function Rules.index(layout)
  local idx = {
    byTag      = {},   -- tag -> lista de regras
    -- Três namespaces INDEPENDENTES. O grupo 2 de um não é o grupo 2
    -- do outro.
    exclusive  = {},   -- "grupo apenas um ativo" -> tags
    onMembers  = {},   -- "grupo ativar"          -> tags
    offMembers = {},   -- "grupo desativar"       -> tags
  }

  -- A chave inclui a PÁGINA: o grupo 4 da página 0 não é o mesmo grupo
  -- 4 da página 1.
  local function key(page, group)
    return ('%d:%d'):format(page or 0, group)
  end

  local function push(bucket, page, group, tag)
    if not group or group == 0 then return end
    local k = key(page, group)
    bucket[k] = bucket[k] or {}
    bucket[k][#bucket[k] + 1] = tag
  end

  idx.key = key

  for _, rule in ipairs(layout.rules or {}) do
    local tag = rule.tag
    if tag then
      idx.byTag[tag] = idx.byTag[tag] or {}
      table.insert(idx.byTag[tag], rule)
      push(idx.exclusive,  rule.page, rule.exclusiveId, tag)
      push(idx.onMembers,  rule.page, rule.onMemberId,  tag)
      push(idx.offMembers, rule.page, rule.offMemberId, tag)
    end
  end

  return idx
end

-- -------------------------------------------------------------- consultas

-- "Ligar o grupo N" atinge o "grupo ativar" N, e SÓ ele.
-- "Desligar o grupo N" atinge o "grupo desativar" N, e SÓ ele.
-- Misturar com o grupo de exclusividade seria contraditório: os membros
-- de um grupo exclusivo não podem ser ligados todos juntos.
local function membersToTurnOn(idx, page, group)
  return idx.onMembers[idx.key(page, group)] or {}
end

local function membersToTurnOff(idx, page, group)
  return idx.offMembers[idx.key(page, group)] or {}
end

--- O controle pertence a algum grupo exclusivo?
function Rules.hasGroups(idx, tag)
  return idx.byTag[tag] ~= nil
end

--- Nomes dos grupos de um controle, para exibir na barra de detalhes.
function Rules.describe(idx, tag)
  local rules = idx.byTag[tag]
  if not rules then return 'sem grupo' end

  local parts = {}
  for _, r in ipairs(rules) do
    local pg = r.page or 0
    if r.exclusiveId then parts[#parts+1] = ('só um ativo %d/p%d'):format(r.exclusiveId, pg) end
    if r.onMemberId then parts[#parts+1] = ('grupo ativar %d/p%d'):format(r.onMemberId, pg) end
    if r.offMemberId then parts[#parts+1] = ('grupo desativar %d/p%d'):format(r.offMemberId, pg) end
    if r.turnOnId then parts[#parts + 1] = ('ao ligar, liga %d'):format(r.turnOnId) end
    if r.turnOffId then parts[#parts + 1] = ('ao ligar, desliga %d'):format(r.turnOffId) end
    if r.turnOnWhenOffId then
      parts[#parts + 1] = ('ao desligar, liga %d'):format(r.turnOnWhenOffId)
    end
    if r.turnOffWhenOffId then
      parts[#parts + 1] = ('ao desligar, desliga %d'):format(r.turnOffWhenOffId)
    end
  end

  if #parts == 0 then return 'sem grupo' end
  return table.concat(parts, ', ')
end

-- ------------------------------------------------------------- aplicação

--- Aplica o acionamento de um controle ao estado.
--
--  @param idx    índice devolvido por Rules.index
--  @param active tabela tag -> booleano, MODIFICADA no lugar
--  @param tag    controle acionado
--  @param force  opcional: true liga, false desliga; nil alterna
--  @return table lista de tags cujo estado MUDOU
--  @return table mapa tag -> valor de TUDO o que foi atribuído
--
--  Os dois retornos são diferentes de propósito. "Mudou" serve para saber
--  o que precisa ser redesenhado. "Atribuído" inclui também as atribuições
--  que não alteraram o booleano, e é isso que os faders precisam:
--
--    Um fader em 30% já conta como "ligado". Se a regra manda ligar o
--    grupo dele, o booleano não muda — mas o cursor PRECISA subir para
--    100%. Usando só a lista de mudanças, o fader ficaria parado em 30%,
--    que era exatamente o sintoma observado na tela.
function Rules.press(idx, active, tag, force)
  local changed  = {}
  local assigned = {}

  local function set(t, value)
    assigned[t] = value
    if (active[t] or false) ~= value then
      active[t] = value
      changed[#changed + 1] = t
    end
  end

  local nowOn
  if force == nil then
    nowOn = not (active[tag] or false)
  else
    nowOn = force and true or false
  end

  set(tag, nowOn)

  local rules = idx.byTag[tag]
  if not rules then return changed, assigned end

  if nowOn then
    for _, rule in ipairs(rules) do
      -- Exclusividade: só um membro do grupo pode ficar aceso.
      if rule.exclusiveId then
        for _, other in ipairs(idx.exclusive[idx.key(rule.page, rule.exclusiveId)] or {}) do
          if other ~= tag then set(other, false) end
        end
      end
      -- Ações disparadas ao ligar.
      if rule.turnOnId then
        for _, t in ipairs(membersToTurnOn(idx, rule.page, rule.turnOnId)) do set(t, true) end
      end
      if rule.turnOffId then
        for _, t in ipairs(membersToTurnOff(idx, rule.page, rule.turnOffId)) do
          if t ~= tag then set(t, false) end
        end
      end
    end
  else
    for _, rule in ipairs(rules) do
      if rule.turnOnWhenOffId then
        for _, t in ipairs(membersToTurnOn(idx, rule.page, rule.turnOnWhenOffId)) do
          if t ~= tag then set(t, true) end
        end
      end
      if rule.turnOffWhenOffId then
        for _, t in ipairs(membersToTurnOff(idx, rule.page, rule.turnOffWhenOffId)) do
          if t ~= tag then set(t, false) end
        end
      end
    end
  end

  return changed, assigned
end

--- Todas as tags que disputam exclusividade com a informada.
--
--  Um controle pode estar em vários grupos "apenas um ativo"; o conjunto
--  é a união de todos eles. Usado na gravação: ao escrever uma cor, as
--  notas das OUTRAS cores precisam sair do trecho, senão duas ficam
--  acesas ao mesmo tempo na timeline.
--
--  @return table tag -> true (não inclui a própria)
function Rules.exclusivePeers(idx, tag)
  local peers = {}
  for _, rule in ipairs(idx.byTag[tag] or {}) do
    if rule.exclusiveId then
      for _, other in ipairs(idx.exclusive[idx.key(rule.page, rule.exclusiveId)] or {}) do
        if other ~= tag then peers[other] = true end
      end
    end
  end
  return peers
end

return Rules
]=], "@core/rules.lua"))(...)
end

-- ============================ core.session
package.preload["core.session"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/session.lua

  O estado vivo de uma sessão: o que está aceso, onde estão os faders,
  o que está sendo segurado com o mouse.

  REGRA DE ARQUITETURA:
    Lua puro. Nunca pode referenciar `reaper` nem `ImGui`.

  POR QUE ESTE MÓDULO EXISTE
    Este estado morava dentro de ui/window.lua. Isso significava que
    para testar "clicar no botão X sobe os faders" era preciso abrir o
    REAPER e olhar com os olhos. Agora é uma chamada de função num
    teste de terminal.

    A separação também deixa explícito quem manda MIDI: este módulo
    NÃO manda. Ele devolve INTENÇÕES — "envie estes comandos", "solte
    estes comandos" — e quem executa é a camada de interface. Assim as
    regras de grupo nunca podem gerar MIDI por acidente.

    As intenções incluem também MUDANÇAS DE ESTADO, com a informação de
    quem causou cada uma: o seu clique ou uma regra de grupo. O gravador
    depende dessa distinção — desligar por clique escreve uma nota de
    desligar, desligar por regra não escreve.

  ------------------------------------------------------------------
  A DIVISÃO DE RESPONSABILIDADE COM O LUMIKIT
  ------------------------------------------------------------------
  Um clique produz exatamente UM envio MIDI: o comando do próprio
  controle. Todas as consequências de grupo — apagar os vizinhos,
  subir os masters — são aplicadas só ao estado local, porque o
  Lumikit já as aplica sozinho ao receber aquele mesmo comando.
------------------------------------------------------------------------]]

local Model = require('core.model')
local Rules = require('core.rules')

local Session = {}

--- Quanto um clique da roda do mouse move um fader (em fração de 0..1).
--  0.04 equivale a cerca de 5 passos de Control Change por clique.
--  PASSO BASE pequeno, com ACELERAÇÃO.
--
--  O fader tem de se mover como fader: passos pequenos, valores
--  intermediários, nada de saltar de 25 em 25. Mas girar devagar até o
--  fim da faixa é trabalhoso.
--
--  A solução é a mesma de qualquer aplicativo moderno: girar devagar dá
--  controle fino; girar rápido acelera. Uma rolada decidida percorre a
--  faixa inteira, e ainda assim passa por dezenas de valores no caminho.
--  PASSO FIXO, escolhido pelo usuário nas Configurações.
--
--  Houve uma versão com aceleração: o passo crescia conforme a
--  velocidade do giro. Na teoria resolve os dois lados; na prática o
--  mesmo gesto dava resultados diferentes e não dava para prever onde o
--  fader ia parar. Previsível vale mais que esperto.
Session.WHEEL_STEP = 0.10
Session.WHEEL_FINE = 0.02

--- Passo mínimo de Control Change para emitir um novo valor.
--
--  Um arrasto de ponta a ponta com passo 1 geraria 128 pontos, o que
--  polui a timeline e não acrescenta nada: a resolução da mão humana e
--  a de um refletor são muito menores que isso. Com passo 4, a mesma
--  varredura vira 32 pontos, e a curva continua suave.
--
--  O extremo exato (0 e 127) é sempre emitido, independentemente do
--  passo: parar em 124 em vez de 127 seria perceptível na luz.
--  Passo 1: cada unidade conta. O afinamento agora é feito DEPOIS, por
--  core/curve.lua, que enxerga o movimento inteiro e sabe quais pontos
--  descrevem o gesto. Filtrar antes descartava as leituras que davam a
--  forma da curva, e o resultado ficava travado.
Session.CC_STEP = 1

-- ---------------------------------------------------------------- criação

--- Cria o estado inicial para um layout.
function Session.new(layout)
  local s = {
    layout    = layout,
    ruleIndex = Rules.index(layout),
    active    = {},   -- tag -> aceso
    faders    = {},   -- tag -> 0..1
    holding   = {},   -- tag -> segurado com o mouse
    lastCC    = {},   -- tag -> último valor de CC efetivamente emitido
    faderTags = {},   -- tag -> true
    byTag     = {},   -- tag -> elemento
  }

  -- Altura MIDI de cada controle, para o cálculo dos rivais abaixo.
  local pitchOf = {}
  for _, e in ipairs(layout.elements) do
    if e.tag and e.commands then
      for _, cmd in ipairs(e.commands) do
        if (cmd.status & 0xF0) == 0x90 then
          pitchOf[e.tag] = cmd.data1
          break
        end
      end
    end
  end

  for _, e in ipairs(layout.elements) do
    if e.tag then
      s.byTag[e.tag] = e

      -- Alturas que disputam exclusividade com esta.
      --
      -- Calculado UMA vez, ao carregar: usar na gravação para apagar as
      -- notas das cores rivais no trecho regravado. Sem isso, regravar
      -- branco por cima de verde deixaria as duas acesas ao mesmo tempo.
      local peers = Rules.exclusivePeers(s.ruleIndex, e.tag)
      local rivals = nil
      for otherTag in pairs(peers) do
        local p = pitchOf[otherTag]
        if p then
          rivals = rivals or {}
          rivals[p] = true
        end
      end
      e.rivalPitches = rivals
      if e.kind == Model.KIND.FADER then
        s.faderTags[e.tag] = true
        -- Fader começa no topo e, portanto, "ligado". Deixar a posição
        -- em 100% e o booleano em nil seria uma incoerência que as
        -- regras herdariam.
        s.faders[e.tag] = 1.0
        s.active[e.tag] = true
      end
    end
  end

  return s
end

-- ------------------------------------------------------------- utilidades

--- Reflete no cursor dos faders o que as regras atribuíram.
--
--  Usa o mapa de ATRIBUIÇÕES, não a lista de mudanças. Um fader em 30%
--  já é "ligado"; mandar ligá-lo não muda o booleano, mas tem de levar
--  o cursor a 100%. Com a lista de mudanças, ele ficaria parado.
local function syncFaders(s, assigned)
  for tag, value in pairs(assigned or {}) do
    if s.faderTags[tag] then
      s.faders[tag] = value and 1.0 or 0.0
    end
  end
end

--- Valor de Control Change correspondente à posição atual de um fader.
function Session.faderCC(s, tag)
  return math.floor((s.faders[tag] or 0) * 127 + 0.5)
end

-- ----------------------------------------------------------------- ações

--- Descreve as mudanças de estado como intenções, marcando a ORIGEM de
--  cada uma: o clique do usuário ou uma regra de grupo.
--
--  O gravador depende dessa distinção. Desligar por clique escreve uma
--  nota que apaga a luz na reprodução; desligar por regra não escreve
--  nada, porque o Lumikit já apaga sozinho ao receber o outro comando.
local function stateIntents(s, intents, changed, pressedTag)
  for _, tag in ipairs(changed) do
    intents[#intents + 1] = {
      action  = 'state',
      tag     = tag,
      element = s.byTag[tag],
      on      = s.active[tag] == true,
      byRule  = (tag ~= pressedTag),
    }
  end
end

--- Aciona um controle comum (alterna aceso/apagado).
--  @return table intenções: { { action = 'send'|'state', ... } }
function Session.press(s, element)
  local tag = element.tag
  local intents = {}

  if tag then
    local changed, assigned = Rules.press(s.ruleIndex, s.active, tag)
    syncFaders(s, assigned)
    stateIntents(s, intents, changed, tag)
  end

  -- Só o comando do PRÓPRIO controle vai para a porta. As consequências
  -- de grupo ficam no estado local: o Lumikit já as aplica sozinho.
  if element.commands and #element.commands > 0 then
    intents[#intents + 1] = { action = 'send', commands = element.commands }
  end

  return intents
end

--- Aperta um controle momentâneo ("acionar apenas enquanto pressionado").
function Session.hold(s, element)
  local tag = element.tag
  local intents = {}
  if tag then
    local changed, assigned = Rules.press(s.ruleIndex, s.active, tag, true)
    syncFaders(s, assigned)
    stateIntents(s, intents, changed, tag)
    s.holding[tag] = true
  end

  if element.commands and #element.commands > 0 then
    intents[#intents + 1] = { action = 'send', commands = element.commands }
  end
  return intents
end

--- Solta um controle momentâneo.
function Session.release(s, element)
  local tag = element.tag
  local intents = {}
  if tag then
    local changed, assigned = Rules.press(s.ruleIndex, s.active, tag, false)
    syncFaders(s, assigned)
    stateIntents(s, intents, changed, tag)
    s.holding[tag] = false
  end

  if element.commands and #element.commands > 0 then
    intents[#intents + 1] = { action = 'release', commands = element.commands }
  end
  return intents
end

--- Move um fader para uma posição absoluta (0..1), vindo do arrasto.
--  @return table intenções (vazia se o valor de CC não mudou)
function Session.setFader(s, element, value)
  local tag = element.tag
  if not tag then return {} end

  if value < 0 then value = 0 elseif value > 1 then value = 1 end

  local before = s.lastCC[tag]
  s.faders[tag] = value
  local after = Session.faderCC(s, tag)

  -- Emite quando o valor andou o bastante, ou quando chegou num extremo.
  -- Sem o passo mínimo, um arrasto despejaria mais de cem mensagens
  -- praticamente idênticas na porta e na timeline.
  local atEdge = (after == 0 or after == 127)
  if before ~= nil then
    local moved = math.abs(after - before)
    if moved == 0 then return {} end
    if moved < Session.CC_STEP and not atEdge then return {} end
  end
  s.lastCC[tag] = after

  s.active[tag] = (after > 0)

  if element.commands and #element.commands > 0 then
    return { {
      action = 'send', commands = element.commands, value = after,
      faderTag = tag, faderValue = after,
    } }
  end
  return {}
end

--- Move um fader pela roda do mouse.
--  @param notches número de cliques da roda (positivo sobe)
--- Velocidade do deslize até o destino, em frações da faixa por segundo.
--
--  4.0 percorre a faixa inteira em um quarto de segundo: rápido o
--  bastante para parecer imediato, lento o bastante para passar por
--  todos os valores no caminho.
Session.RAMP_RATE = 4.0

--- Máximo de mensagens de Control Change por fader, por quadro.
--
--  Emitir cada valor inteiro dá o movimento mais liso possível, mas com
--  cinco faders varrendo ao mesmo tempo chega a quarenta mensagens num
--  quadro só. A porta satura e passa a DERRUBAR mensagens — inclusive
--  os Note On dos botões, que é o sintoma de "o Lumikit não recebe".
--
--  Quatro por quadro, a 60 quadros por segundo, são 240 valores por
--  segundo: mais que suficiente para o olho ver um movimento contínuo.
Session.RAMP_MAX_PER_FRAME = 4

--- Máximo de mensagens por quadro somando TODOS os faders.
--
--  O limite por fader não basta: cinco faders varrendo ao mesmo tempo
--  davam vinte mensagens num quadro. O que satura a porta é o total.
Session.RAMP_MAX_TOTAL = 8

--- A roda define um DESTINO; o fader desliza até ele.
--
--  Aplicar o salto de uma vez fazia o fader pular de 0 para 10, de 10
--  para 40 — e o Lumikit recebia degraus em vez de um movimento. Agora
--  a roda só diz aonde ir, e Session.rampFaders leva o fader até lá
--  passando por cada valor.
--
--  @param fine com Shift: passo menor, para acerto fino
function Session.wheelFader(s, element, notches, fine)
  local tag = element.tag
  if not tag then return {} end

  local passo = fine and Session.WHEEL_FINE or Session.WHEEL_STEP
  s.faderTarget = s.faderTarget or {}

  -- Parte do destino atual, não da posição: giros seguidos somam, em
  -- vez de reiniciar a conta a cada clique.
  local base = s.faderTarget[tag] or s.faders[tag] or 0
  local alvo = base + notches * passo
  if alvo < 0 then alvo = 0 elseif alvo > 1 then alvo = 1 end

  s.faderTarget[tag] = alvo
  return {}
end

--- Define o DESTINO do fader por um valor absoluto (0..1), em vez de um
--  passo relativo. Usada pelos grupos de fader no modo "mesmo valor"
--  (ui/window.lua): todo o grupo mira o mesmo alvo, calculado uma vez só
--  fora daqui, e cada fader entra aqui só para receber esse mesmo número.
--
--  Mesmo mecanismo de destino/deslize do wheelFader — Session.rampFaders
--  não distingue como o alvo chegou lá, então o resto do caminho (envio
--  MIDI, gravação) já funciona sem mudança nenhuma.
function Session.setFaderTarget(s, element, value)
  local tag = element.tag
  if not tag then return end

  if value < 0 then value = 0 elseif value > 1 then value = 1 end
  s.faderTarget = s.faderTarget or {}
  s.faderTarget[tag] = value
end

--- Avança os faders em direção aos seus destinos.
--
--  Chamado a cada quadro. Devolve as intenções de envio dos valores por
--  onde o fader passou, para o Lumikit receber o movimento inteiro.
--
--  @param dt tempo desde o quadro anterior, em segundos
function Session.rampFaders(s, dt)
  if not s.faderTarget or not next(s.faderTarget) then return {} end

  local intents = {}
  local avanco = Session.RAMP_RATE * math.min(dt or 0.016, 0.1)

  -- Quantos faders estão deslizando agora: o orçamento de mensagens é
  -- dividido entre eles.
  local ativos = 0
  for _ in pairs(s.faderTarget) do ativos = ativos + 1 end
  local porFader = math.max(1,
    math.floor(math.min(Session.RAMP_MAX_PER_FRAME,
                        Session.RAMP_MAX_TOTAL / math.max(1, ativos))))

  for tag, alvo in pairs(s.faderTarget) do
    local atual = s.faders[tag] or 0
    local antes = atual
    local falta = alvo - atual

    if math.abs(falta) <= avanco then
      -- Chegou: aplica o valor exato e encerra o deslize.
      s.faderTarget[tag] = nil
      atual = alvo
    else
      atual = atual + (falta > 0 and avanco or -avanco)
    end

    local element = s.byTag[tag]
    if element then
      -- Emite CADA valor inteiro atravessado neste quadro.
      --
      -- Um quadro dura 16 ms e o fader pode andar dez unidades nele.
      -- Mandar só o valor final faria o Lumikit receber degraus de dez
      -- em dez — que é justamente o salto que o deslize existe para
      -- eliminar.
      local de  = math.floor((antes or atual) * 127 + 0.5)
      local ate = math.floor(atual * 127 + 0.5)

      if de == ate then
        for _, it in ipairs(Session.setFader(s, element, atual)) do
          intents[#intents + 1] = it
        end
      else
        -- Distribui os valores atravessados em no máximo N passos, para
        -- o movimento continuar liso sem saturar a porta MIDI.
        local dir = (ate > de) and 1 or -1
        local total = math.abs(ate - de)
        local passos = math.min(total, porFader)

        for i = 1, passos do
          local v = de + dir * math.floor(total * i / passos + 0.5)
          for _, it in ipairs(Session.setFader(s, element, v / 127)) do
            intents[#intents + 1] = it
          end
        end
      end
    end
  end

  return intents
end

--- Escolhe À MÃO qual controle é o release desta tela.
--
--  A busca por nome acerta na maioria dos .form, mas não em todos: quem
--  monta a tela batiza os controles como quiser, e mais de um projeto
--  chama o release de outra coisa. Sem poder apontar o certo, restava
--  editar o .form no Lumikit e reexportar.
--
--  @param tag  tag do controle, ou nil para voltar à busca por nome
function Session.setReleaseTag(s, tag)
  s.releaseTag = tag
end

--- Localiza um controle que sirva de "release all", se houver.
--
--  Precisa ter mapeamento MIDI: sem isso não há mensagem para enviar
--  nem para gravar. No arquivo de referência NENHUM controle atende —
--  BACKOUT e RELEASE ALL existem na tela mas não têm MIDI. Para usar o
--  release de verdade é preciso mapeá-lo no Lumikit e reexportar.
--
--  A escolha do usuário vem PRIMEIRO: se ele apontou um controle, é
--  aquele, e a busca por nome nem chega a rodar.
--
--  @return elemento ou nil
function Session.findRelease(s)
  if s.releaseTag then
    local e = s.byTag[s.releaseTag]
    if e and e.commands and #e.commands > 0 then return e end
  end

  local ALVOS = { 'RELEASE ALL', 'RELEASE', 'BACKOUT', 'BLACKOUT' }
  for _, alvo in ipairs(ALVOS) do
    for _, e in pairs(s.byTag) do
      local nome = (e.text or ''):upper()
      if nome == alvo and e.commands and #e.commands > 0 then
        return e
      end
    end
  end
  return nil
end

--- Apaga tudo: o "release all" de início de música.
--
--  Devolve as intenções de envio necessárias para o Lumikit também
--  apagar. Como os controles são toggle, apagar significa mandar o
--  comando de cada um que está aceso — o Lumikit alterna a cada Note On
--  que recebe.
--
--  @return table intenções de envio
function Session.releaseAll(s)
  local intents = {}

  -- Se o .form tiver um controle de release mapeado, ele é o caminho
  -- certo: uma mensagem só, e o Lumikit apaga tudo por conta própria —
  -- inclusive o que a LumiBridge não sabe que está aceso.
  local release = Session.findRelease(s)
  if release then
    for tag in pairs(s.active) do s.active[tag] = false end
    return { {
      action = 'send', commands = release.commands, element = release,
      releasing = true, viaRelease = true,
    } }
  end

  -- Sem controle de release: desliga um a um o que sabemos estar aceso.
  -- Não dá para ir além disso — os controles são toggle, então mandar o
  -- comando de um que já está apagado o LIGARIA.
  local tags = {}
  for tag, on in pairs(s.active) do
    if on then tags[#tags + 1] = tag end
  end
  table.sort(tags)

  for _, tag in ipairs(tags) do
    local element = s.byTag[tag]
    if element and element.commands and #element.commands > 0
       and not s.faderTags[tag] then
      intents[#intents + 1] = {
        action = 'send', commands = element.commands, element = element,
        releasing = true,
      }
    end
    s.active[tag] = false
  end

  return intents
end

--- Reflete na tela quais controles estão soando na timeline.
--
--  Recebe o conjunto de alturas que estão tocando e acende exatamente
--  os controles correspondentes. Não passa pelas regras de grupo: o que
--  está gravado JÁ é o resultado delas, e reaplicá-las aqui poderia
--  apagar um controle que a gravação diz estar aceso.
--  @param skip tabela tag -> true de controles a NÃO mexer (os que o
--              usuário está gravando neste momento)
--  @return table lista de { element, on } que MUDARAM de estado
function Session.applySounding(s, pitches, ccValues, skip)
  local mudou = {}
  for tag, element in pairs(s.byTag) do
   if not (skip and skip[tag]) then
    local pitch, cc = nil, nil
    for _, cmd in ipairs(element.commands or {}) do
      local kind = cmd.status & 0xF0
      if kind == 0x90 and not pitch then pitch = cmd.data1 end
      if kind == 0xB0 and not cc then cc = cmd.data1 end
    end

    if s.faderTags[tag] then
      -- Faders seguem o valor de Control Change gravado.
      if cc and ccValues and ccValues[cc] then
        local v = ccValues[cc] / 127
        s.faders[tag] = v
        s.active[tag] = v > 0
      end
    elseif pitch then
      -- Botões: acesos enquanto a nota estiver soando. Vale igual para
      -- toggle e momentâneo, porque a timeline já guarda a duração real
      -- de cada um.
      local novo = pitches[pitch] == true
      if (s.active[tag] == true) ~= novo then
        s.active[tag] = novo
        mudou[#mudou + 1] = { element = element, on = novo }
      end
    end
   end
  end
  return mudou
end

-- ---------------------------------------------------------------- atalhos

--- Lista os atalhos de teclado declarados no .form.
--
--  Controles COBERTOS entram na lista de propósito. Esconder um botão
--  atrás de outro é como o usuário mantém uma função acessível só pelo
--  teclado; tirá-los daqui removeria exatamente o que ele quis manter.
--
--  Controles de tamanho zero ficam de fora: esses sim são resíduo.
--
--  @return table { { code = 90, element = ... }, ... }
function Session.shortcuts(layout)
  local out = {}
  for _, e in ipairs(layout.elements) do
    if e.key and not e.hidden then
      out[#out + 1] = { code = e.key, element = e, covered = e.covered == true }
    end
  end
  return out
end

-- ---------------------------------------------------------------- leitura

function Session.isActive(s, element, fallbackKey)
  local key = element.tag or fallbackKey
  return s.active[key] == true
end

function Session.faderValue(s, element, fallbackKey)
  local key = element.tag or fallbackKey
  return s.faders[key] or 1.0
end

return Session
]=], "@core/session.lua"))(...)
end

-- ============================ core.icons
package.preload["core.icons"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/icons.lua

  Decodifica os ícones do .form e os converte em PNG.

  REGRA DE ARQUITETURA:
    Lua puro. Nunca pode referenciar `reaper` nem `ImGui`.

  ------------------------------------------------------------------
  O FORMATO DO ÍCONE
  ------------------------------------------------------------------
  Cada ícone é uma string de 1024 caracteres = um bitmap 32x32, um
  caractere por pixel. Cada letra é um índice de cor.

  IMPORTANTE: a tabela de cores NÃO está no .form. As letras apontam
  para uma paleta que vive dentro do Lumikit. A paleta abaixo foi
  medida pixel a pixel comparando os ícones com uma captura de tela
  da Janela Personalizada — o registro bateu com precisão exata
  (461 pixels da letra G no bitmap, 461 pixels vermelhos na captura).

  Consequência prática: se um dia as cores saírem erradas, o ajuste é
  nesta tabela e em nenhum outro lugar.

  ------------------------------------------------------------------
  A COR TRANSPARENTE: O PIXEL (0,0)
  ------------------------------------------------------------------
  O Lumikit trata UMA cor do ícone como fundo transparente, e essa cor
  é a do primeiro pixel do bitmap — o canto superior esquerdo.

  Isso vem de como os ícones são desenhados na prática. Quando o
  desenho usa preto e branco, é preciso escolher uma TERCEIRA cor para
  servir de fundo, senão o próprio desenho sumiria. Essa terceira cor
  é pintada nos quatro cantos, e o resultado visual é o canto
  arredondado que aparece nos ícones.

  A medição confirma: em todos os 28 ícones coloridos deste arquivo, a
  letra do canto aparece EXATAMENTE 12 vezes — quatro cantos de três
  pixels. E a letra varia entre G, O, N e R conforme o desenho, porque
  é apenas uma cor sobrando naquele ícone específico.

  Nos ícones monocromáticos a mesma regra vale, só que ali a cor do
  canto é o fundo inteiro.

  ------------------------------------------------------------------
  AS TRÊS REGRAS  (verificadas em 101 de 101 ícones)
  ------------------------------------------------------------------
  1. A PALETA É FIXA. Cada letra é sempre a mesma cor.

  2. A LETRA DO PIXEL (0,0) É A TRANSPARENTE daquele bitmap. É por isso
     que os ícones aparecem com o canto arredondado: o autor pinta os
     cantos com a cor que escolheu para ser o fundo.

     Qual letra cumpre esse papel muda de ícone para ícone. Se o desenho
     usa preto e branco ao mesmo tempo, o autor pinta o fundo com uma
     terceira cor, e é essa terceira que some.

  3. EXISTEM DOIS BITMAPS POR FUNÇÃO. `image` é o estado ligado,
     `imageOff` o desligado. Quando existem os dois, costumam ser um o
     negativo do outro — no FLOR, image tem A=249/X=775 e imageOff tem
     exatamente o inverso, A=775/X=249, o que troca qual letra fica no
     canto e portanto inverte as cores do desenho.

  Essa terceira regra foi a última a aparecer e explicava sozinha todas
  as aparentes contradições. Comparando o bitmap LIGADO contra botões
  que estavam DESLIGADOS na captura de tela, sete ícones pareciam sair
  com a cor trocada. Usando o bitmap certo para cada estado, o
  casamento é de 100%.
------------------------------------------------------------------------]]

local Icons = {}

Icons.SIZE = 32

--- Paleta letra -> cor. `false` significa transparente.
--
--  Medida a partir da captura de tela; ver o cabeçalho. Os valores com
--  contagem alta são os mais confiáveis.
Icons.PALETTE = {
  A = { 255, 255, 255 },   -- branco
  G = { 255,   0,   0 },   -- vermelho
  X = {   0,   0,   0 },   -- preto
  S = {   0, 255,   0 },   -- verde puro
  R = {   0, 255,  64 },   -- verde
  O = {   0,   0, 255 },   -- azul
  J = { 255,   0, 255 },   -- magenta
  M = { 128, 255, 255 },   -- ciano claro
  C = { 255, 255,   0 },   -- amarelo
  V = { 253, 128,   0 },   -- laranja
  U = { 243, 189,  75 },   -- âmbar
  K = { 146,  37, 126 },   -- roxo
  N = { 255, 255, 255 },   -- branco
}

--- Cor usada para letras fora da paleta. Branco em vez de transparente,
--  para que uma letra desconhecida apareça na tela em vez de sumir.
Icons.FALLBACK = { 255, 255, 255 }

-- ------------------------------------------------------------- decodificação

--- A cor transparente do ícone: a letra do pixel (0,0).
--
--  Simples de propósito, e confirmada em 101 de 101 ícones. Uma
--  heurística mais elaborada — a letra mais comum na moldura externa —
--  acerta os monocromáticos mas erra os coloridos, onde a transparência
--  ocupa só os doze pixels dos cantos arredondados e a moldura é uma
--  cor cheia e visível.
local function transparentLetter(data)
  return data:sub(1, 1)
end

--- Converte um ícone em pixels RGBA.
--  @param data string de 1024 caracteres
--  @return string bytes RGBA (32*32*4), ou nil
function Icons.toRGBA(data)
  if type(data) ~= 'string' or #data ~= Icons.SIZE * Icons.SIZE then
    return nil
  end

  local transparent = transparentLetter(data)

  local out, n = {}, 0

  -- Cache por letra: 1024 consultas viram no máximo 13.
  local cache = {}
  local TRANSPARENT = '\0\0\0\0'

  local function colorOf(ch)
    local c = cache[ch]
    if c ~= nil then return c end

    local entry
    if ch == transparent then
      -- Só a letra do canto é fundo. Uma letra preta ou branca que NÃO
      -- esteja no canto continua sendo desenho — é isso que permite
      -- desenhar em preto usando uma terceira cor como fundo.
      --
      -- ATENÇÃO: não usar `(ch == transparent) and false or COR` aqui.
      -- O idioma ternário do Lua quebra quando o ramo verdadeiro vale
      -- `false`: `true and false` é false, e o `or` devolve o segundo
      -- valor. O ícone inteiro sairia sólido.
      entry = false
    else
      entry = Icons.PALETTE[ch] or Icons.FALLBACK
    end

    if entry == false then
      c = TRANSPARENT
    else
      c = string.char(entry[1], entry[2], entry[3], 255)
    end
    cache[ch] = c
    return c
  end

  for i = 1, #data do
    n = n + 1
    out[n] = colorOf(data:sub(i, i))
  end

  return table.concat(out)
end

-- --------------------------------------------------------------- PNG

-- Codificador PNG mínimo, em Lua puro.
--
-- Por que escrever um: o REAPER não traz biblioteca de imagem, e desenhar
-- 1024 retângulos por botão a cada quadro seria inviável — com 101 botões
-- daria mais de cem mil chamadas de desenho por quadro. Gerando um PNG uma
-- vez por ícone, o desenho vira uma única chamada de imagem.
--
-- O PNG usa blocos deflate "armazenados" (sem compressão). São ~4 KB por
-- ícone em vez de ~1 KB, o que é irrelevante aqui e dispensa implementar
-- um compressor inteiro.

local crcTable
local function crc32(s, crc)
  if not crcTable then
    crcTable = {}
    for i = 0, 255 do
      local c = i
      for _ = 1, 8 do
        if c & 1 == 1 then c = 0xEDB88320 ~ (c >> 1) else c = c >> 1 end
      end
      crcTable[i] = c
    end
  end
  crc = crc or 0xFFFFFFFF
  for i = 1, #s do
    crc = crcTable[(crc ~ s:byte(i)) & 0xFF] ~ (crc >> 8)
  end
  return crc
end

local function be32(v)
  return string.char((v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF)
end

local function chunk(kind, data)
  local crc = crc32(kind .. data) ~ 0xFFFFFFFF
  return be32(#data) .. kind .. data .. be32(crc & 0xFFFFFFFF)
end

local function adler32(s)
  local a, b = 1, 0
  for i = 1, #s do
    a = (a + s:byte(i)) % 65521
    b = (b + a) % 65521
  end
  return (b << 16) | a
end

--- Empacota bytes RGBA num arquivo PNG.
--  @param rgba string de w*h*4 bytes
--  @return string conteúdo do PNG
function Icons.toPNG(rgba, w, h)
  w = w or Icons.SIZE
  h = h or Icons.SIZE
  if not rgba or #rgba ~= w * h * 4 then return nil end

  -- Cada linha do PNG começa com um byte de filtro; usamos 0 (nenhum).
  local rows = {}
  for y = 0, h - 1 do
    rows[#rows + 1] = '\0' .. rgba:sub(y * w * 4 + 1, (y + 1) * w * 4)
  end
  local raw = table.concat(rows)

  -- zlib: cabeçalho, blocos armazenados, adler32.
  local parts = { '\x78\x01' }
  local pos, MAX = 1, 65535
  while pos <= #raw do
    local piece = raw:sub(pos, pos + MAX - 1)
    local last = (pos + MAX - 1 >= #raw) and 1 or 0
    local len = #piece
    parts[#parts + 1] = string.char(last)
      .. string.char(len & 0xFF, (len >> 8) & 0xFF)
      .. string.char((~len) & 0xFF, ((~len) >> 8) & 0xFF)
      .. piece
    pos = pos + MAX
  end
  parts[#parts + 1] = be32(adler32(raw))

  local ihdr = be32(w) .. be32(h) .. '\8\6\0\0\0'   -- 8 bits, RGBA
  return '\137PNG\r\n\26\n'
    .. chunk('IHDR', ihdr)
    .. chunk('IDAT', table.concat(parts))
    .. chunk('IEND', '')
end

--- Escolhe o bitmap conforme o estado do controle.
--  @param element elemento do modelo (tem .icon e .iconOff)
--  @param active  o controle está aceso?
--  @return tabela do ícone, ou nil
function Icons.forState(element, active)
  if active then
    return element.icon
  end
  return element.iconOff or element.icon
end

--- Converte direto de ícone para PNG.
function Icons.iconToPNG(data)
  local rgba = Icons.toRGBA(data)
  if not rgba then return nil end
  return Icons.toPNG(rgba, Icons.SIZE, Icons.SIZE)
end

--- Posição do ícone dentro de um botão, em coordenadas do .form.
--
--  Medido na captura de tela: o ícone fica centralizado na horizontal e
--  centralizado na área abaixo da faixa do texto.
--  @return x, y (relativos ao canto do botão)
function Icons.placement(buttonW, buttonH, captionBand)
  captionBand = captionBand or 16
  local x = (buttonW - Icons.SIZE) / 2
  local y = captionBand + (buttonH - captionBand - Icons.SIZE) / 2
  if y < captionBand then y = captionBand end
  return x, y
end

return Icons
]=], "@core/icons.lua"))(...)
end

-- ============================ core.calibration
package.preload["core.calibration"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/calibration.lua

  Mede o seu atraso de reação para compensá-lo na gravação.

  REGRA DE ARQUITETURA:
    Lua puro. Nunca pode referenciar `reaper` nem `ImGui`.

  ------------------------------------------------------------------
  POR QUE ISSO É NECESSÁRIO
  ------------------------------------------------------------------
  Você clica DEPOIS de ouvir a batida. Entre ouvir e o dedo descer há
  algo entre 150 e 250 ms, e ainda existe a granularidade do laço de
  quadros da interface. Sem compensar, tudo cai atrasado.

  O encaixe na grade sozinho não resolve: se o atraso passar de meio
  quadradinho, a nota encaixa no quadradinho ERRADO — e a 120 BPM com
  grade de 1/16, meio quadradinho são só 62 ms.

  ------------------------------------------------------------------
  COMO A MEDIÇÃO FUNCIONA
  ------------------------------------------------------------------
  Você toca a música e clica no tempo da batida várias vezes. Para cada
  clique guardamos a distância até a batida mais próxima. O atraso
  adotado é a MEDIANA dessas distâncias, não a média: um clique perdido
  ou muito fora arrastaria a média e não move a mediana.

  Descartamos também as amostras absurdas (acima do limite) antes de
  calcular, porque um clique fora do compasso não é atraso de reação.
------------------------------------------------------------------------]]

local Calibration = {}

--- Amostras acima disto (em segundos) são consideradas erro de execução,
--  não latência, e ficam de fora do cálculo.
Calibration.MAX_PLAUSIBLE = 0.6

--- Amostras necessárias para o resultado ser confiável.
Calibration.MIN_SAMPLES = 4

function Calibration.new()
  return { samples = {} }
end

--- Mede o atraso de um clique em relação à BATIDA mais próxima.
--
--  Mede contra a semínima e NÃO contra a grade do projeto. Você bate
--  junto com a batida, não com o quadradinho: numa grade de 1/32 a
--  120 BPM, cada quadradinho dura 62 ms, e um atraso de 200 ms cairia
--  mais perto do quadradinho seguinte — a medida sairia errada até no
--  sinal.
--
--  @param qn posição do clique em semínimas
--  @return segundos de atraso (positivo = você clicou depois da batida)
function Calibration.beatDelta(qn, secondsPerQN)
  local beat = math.floor(qn + 0.5)
  return (qn - beat) * (secondsPerQN or 0.5)
end

--- Observa um clique normal de trabalho, sem rotina de calibração.
--
--  A ideia: quando você programa, tende a clicar perto das batidas. Se
--  os cliques ficam sistematicamente atrasados na MESMA medida, isso é
--  a sua latência. Amostras longe de qualquer batida são descartadas,
--  porque não dizem nada sobre atraso — podem ser síncopes de verdade.
--
--  @return boolean a amostra foi aproveitada?
function Calibration.observe(cal, qn, secondsPerQN)
  local delta = Calibration.beatDelta(qn, secondsPerQN)
  -- Perto de metade da distância entre batidas: além disso não dá para
  -- saber se o clique estava atrasado nesta batida ou adiantado na
  -- seguinte. O limite não pode ser apertado demais — um atraso de
  -- 200 ms a 120 BPM já vale 0,4 semínima, e é um atraso comum.
  if math.abs(delta) > (secondsPerQN or 0.5) * 0.45 then return false end
  return Calibration.tap(cal, delta)
end

function Calibration.reset(cal)
  cal.samples = {}
end

--- Registra um toque.
--  @param delta segundos entre o clique e a batida mais próxima.
--               Positivo significa que você clicou depois da batida.
function Calibration.tap(cal, delta)
  if type(delta) ~= 'number' then return false end
  if math.abs(delta) > Calibration.MAX_PLAUSIBLE then return false end
  cal.samples[#cal.samples + 1] = delta
  return true
end

function Calibration.count(cal)
  return #cal.samples
end

function Calibration.ready(cal)
  return #cal.samples >= Calibration.MIN_SAMPLES
end

--- Mediana das amostras, em segundos.
--  @return número|nil, e a quantidade de amostras usadas
function Calibration.result(cal)
  local n = #cal.samples
  if n == 0 then return nil, 0 end

  local sorted = {}
  for i = 1, n do sorted[i] = cal.samples[i] end
  table.sort(sorted)

  local median
  if n % 2 == 1 then
    median = sorted[(n + 1) // 2]
  else
    median = (sorted[n // 2] + sorted[n // 2 + 1]) / 2
  end
  return median, n
end

--- Dispersão das amostras, para você saber se a medição foi consistente.
--  @return desvio médio absoluto em segundos, ou nil
function Calibration.spread(cal)
  local median, n = Calibration.result(cal)
  if not median or n == 0 then return nil end
  local sum = 0
  for _, v in ipairs(cal.samples) do sum = sum + math.abs(v - median) end
  return sum / n
end

--- Texto pronto para a interface.
function Calibration.describe(cal)
  local median, n = Calibration.result(cal)
  if not median then
    return ('%d toques — clique no tempo da batida'):format(Calibration.count(cal))
  end
  local spread = Calibration.spread(cal) or 0
  local quality
  if not Calibration.ready(cal) then
    quality = 'poucos toques ainda'
  elseif spread <= 0.03 then
    quality = 'consistente'
  elseif spread <= 0.07 then
    quality = 'aceitável'
  else
    quality = 'irregular, vale repetir'
  end
  return ('%d toques · atraso %.0f ms · variação %.0f ms · %s')
    :format(n, median * 1000, spread * 1000, quality)
end

return Calibration
]=], "@core/calibration.lua"))(...)
end

-- ============================ core.recorder
package.preload["core.recorder"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/recorder.lua

  Decide O QUE escrever na timeline. Não escreve nada.

  REGRA DE ARQUITETURA:
    Lua puro. Nunca pode referenciar `reaper` nem `ImGui`.
    Trabalha em QN (semínimas), não em segundos: assim a gravação
    acompanha mudanças de andamento e o módulo fica testável.

  ------------------------------------------------------------------
  COMO CADA TIPO DE CONTROLE É DESENHADO
  ------------------------------------------------------------------
  BOTÃO TOGGLE
    Ao ligar, abre uma LINHA que cresce enquanto o botão fica aceso.
    Ao desligar, a linha é fechada e uma NOTA CURTA é escrita no fim.

    A linha é o que você vê; a nota curta é o que efetivamente desliga
    no Lumikit. Isso é obrigatório, não estética: o Lumikit aciona no
    Note On e ignora o Note Off, então uma linha sozinha ligaria a luz
    e nunca a apagaria.

    A linha termina um pouco antes da nota curta para os dois eventos
    não se fundirem no editor.

  BOTÃO MOMENTÂNEO
    Uma linha só, do apertar ao soltar. Aqui o Note Off é real e o
    comportamento casa exatamente, sem nota extra.

  FADER
    Control Change no instante do movimento, sem encaixe na grade —
    movimento de fader é contínuo, encaixar destruiria a curva.

  ------------------------------------------------------------------
  DESLIGAR POR CLIQUE  x  DESLIGAR POR REGRA DE GRUPO
  ------------------------------------------------------------------
  Quando você aciona VERM PURO, o Lumikit apaga BRANCO PURO sozinho.
  A linha do BRANCO PURO PRECISA ser fechada, senão fica desenhada como
  acesa para sempre. Mas ela NÃO pode receber a nota curta de desligar:
  o Lumikit já desligou por conta própria, e a nota extra ligaria de
  volta na reprodução.

  Fechar a linha sem escrever a nota. É a mesma separação entre "o que
  é enviado" e "o que é desenhado" que vale nas regras de grupo.
------------------------------------------------------------------------]]

local Recorder = {}

--- Velocity da nota que DESLIGA. O Lumikit ignora velocity (usedata2 é
--  false nos 99 mapeamentos), então ela fica livre para uso visual: o
--  Piano Roll colore as notas por velocity e você distingue liga de
--  desliga de relance.
--- Velocity da nota que desliga.
--
--  Igual à de ligar, e não um valor menor. O Lumikit ignora a velocity
--  (usedata2="false" nos 99 mapeamentos), mas o valor máximo é o que
--  você usa hoje no Piano Roll e é o que garante o mesmo comportamento
--  se um dia esse mapeamento mudar.
Recorder.OFF_VELOCITY = 127

--- Velocity de TODA nota gravada. Sempre 127, sem exceção.
--
--  Antes vinha do data2 do .form, que varia de controle para controle
--  (73, 101, 103...). Duas consequências ruins: o Piano Roll colore as
--  notas por velocity, então uma nota reescrita com valor diferente
--  aparecia como se estivesse partida em duas; e o item de referência
--  feito à mão usa 127 em todas as notas.
--
--  O Lumikit ignora a velocity de qualquer forma: usedata2="false" nos
--  99 mapeamentos do arquivo.
Recorder.VELOCITY = 127

--- Comprimento mínimo de uma linha, em frações da grade.
Recorder.MIN_LENGTH_GRIDS = 1

--- Folga entre o fim da linha e o início da nota de desligar, em
--  frações da grade. Impede que o editor funda os dois eventos.
--- Espaço entre o fim da linha e a nota que desliga.
--
--  ZERO, de propósito. A nota de desligar precisa cair no INSTANTE em
--  que você soltou o botão: qualquer folga aqui vira atraso visível na
--  luz apagando. As duas notas se encostam, e é assim que deve ser.
Recorder.GAP_GRIDS = 0

-- ------------------------------------------------------------- criação

function Recorder.new(gridQN)
  return {
    gridQN = gridQN or 0.25,   -- 0.25 QN = 1/16
    open   = {},               -- tag -> linha aberta
    written = 0,
  }
end

function Recorder.setGrid(rec, gridQN)
  if gridQN and gridQN > 0 then rec.gridQN = gridQN end
end

--- Há alguma linha aberta?
function Recorder.hasOpen(rec)
  return next(rec.open) ~= nil
end

function Recorder.openCount(rec)
  local n = 0
  for _ in pairs(rec.open) do n = n + 1 end
  return n
end

-- ---------------------------------------------------------- grade

--- Encaixa uma posição na grade mais próxima.
function Recorder.snap(rec, qn)
  local g = rec.gridQN
  return math.floor(qn / g + 0.5) * g
end

-- -------------------------------------------------------- utilidades

local function firstNoteCommand(element)
  for _, cmd in ipairs(element.commands or {}) do
    if (cmd.status & 0xF0) == 0x90 then return cmd end
  end
  return nil
end

local function firstCCCommand(element)
  for _, cmd in ipairs(element.commands or {}) do
    if (cmd.status & 0xF0) == 0xB0 then return cmd end
  end
  return nil
end

-- ------------------------------------------------------------ ações

--- Abre uma linha para um controle que acabou de acender.
--  @return table intenções (vazia: a nota só é escrita ao fechar)
function Recorder.noteOn(rec, element, qn)
  local cmd = firstNoteCommand(element)
  if not cmd or not element.tag then return {} end

  -- Já havia linha aberta: fecha a anterior antes de abrir outra, para
  -- não perder o trecho nem deixar duas linhas empilhadas.
  local intents = {}
  if rec.open[element.tag] then
    intents = Recorder.noteOff(rec, element, qn, true)
  end

  local startQN = Recorder.snap(rec, qn)
  -- A primeira célula é reservada ao Release All. Qualquer coisa que
  -- caia nela é empurrada para a seguinte, senão o release e o primeiro
  -- comando disputariam a mesma posição e o Lumikit receberia os dois
  -- juntos no arranque.
  startQN = Recorder.afterRelease(rec, startQN)

  rec.open[element.tag] = {
    startQN   = startQN,
    -- Alturas que não podem soar junto com esta (mesmo grupo exclusivo).
    rivals    = element.rivalPitches,
    channel   = cmd.channel,
    pitch     = cmd.data1,
    velocity  = Recorder.VELOCITY,
    momentary = element.momentary == true,
    name      = element.text,
  }

  -- GRAVAÇÃO AO VIVO: a nota nasce agora, com uma célula de comprimento,
  -- e vai crescendo enquanto o botão estiver aceso.
  --
  -- Antes ela só era escrita ao desligar. Isso tinha duas consequências
  -- ruins: nada aparecia na timeline durante a execução, e terminar a
  -- gravação com um botão ainda ligado perdia a nota inteira.
  intents[#intents + 1] = {
    kind     = 'note',
    live     = element.tag,          -- marca a nota como "em crescimento"
    channel  = cmd.channel,
    pitch    = cmd.data1,
    velocity = Recorder.VELOCITY,
    startQN  = startQN,
    endQN    = startQN + rec.gridQN,
    label    = element.text,
    rivals   = element.rivalPitches,
  }

  return intents
end

--- Define até onde uma linha pode crescer.
function Recorder.setLimit(rec, tag, limitQN)
  local line = rec.open[tag]
  if line then line.limitQN = limitQN end
end

--- Entra em gravação no meio da música, assumindo o estado atual.
--
--  Abre uma linha para cada controle que já está aceso, começando no
--  ponto do punch. Combinado com o corte feito na timeline, o resultado
--  é uma nota nova que continua exatamente de onde a anterior parou.
--
--  @param elements lista de elementos acesos naquele ponto
--  @return table intenções de escrita
function Recorder.punchIn(rec, elements, qn)
  local out = {}
  local base = Recorder.snap(rec, qn)
  base = Recorder.afterRelease(rec, base)

  for _, element in ipairs(elements or {}) do
    local cmd = firstNoteCommand(element)
    if cmd and element.tag and not rec.open[element.tag] then
      rec.open[element.tag] = {
        startQN   = base,
        rivals    = element.rivalPitches,
        channel   = cmd.channel,
        pitch     = cmd.data1,
        velocity  = Recorder.VELOCITY,
        momentary = element.momentary == true,
        name      = element.text,
      }
      out[#out + 1] = {
        kind     = 'note',
        live     = element.tag,
        channel  = cmd.channel,
        pitch    = cmd.data1,
        velocity = Recorder.VELOCITY,
        startQN  = base,
        endQN    = base + rec.gridQN,
        label    = element.text,
        rivals   = element.rivalPitches,
      }
    end
  end

  return out
end

--- Primeira célula da região, reservada ao Release All.
function Recorder.setReleaseCell(rec, qn)
  rec.releaseQN = qn and Recorder.snap(rec, qn) or nil
end

--- Empurra para fora da célula do release, se necessário.
function Recorder.afterRelease(rec, qn)
  if rec.releaseQN and qn < rec.releaseQN + rec.gridQN - 1e-9 then
    return rec.releaseQN + rec.gridQN
  end
  return qn
end

--- Estende as notas ao vivo até a posição atual.
--
--  Chamado a cada quadro enquanto grava. É o que faz a nota crescer na
--  tela como numa gravação de áudio.
--
--  @return table intenções de atualização
function Recorder.growLive(rec, qn)
  local out = {}
  for tag, line in pairs(rec.open) do
    local fim = math.max(qn, line.startQN + rec.gridQN)

    -- LIMITE: a nota não passa por cima do próximo evento já programado.
    --
    -- Sem isso, regravar uma cor no meio da música apagaria todas as
    -- trocas seguintes daquele grupo, porque a nota cresceria por cima
    -- delas até o fim. Com o limite, a mudança vale só até o próximo
    -- evento — que sobrevive intacto.
    if line.limitQN and fim > line.limitQN then fim = line.limitQN end
    -- Só emite quando cresceu de verdade, para não reescrever a mesma
    -- nota sessenta vezes por segundo.
    if not line.lastEnd or math.abs(fim - line.lastEnd) > rec.gridQN * 0.25 then
      line.lastEnd = fim
      out[#out + 1] = {
        kind     = 'update',
        live     = tag,
        channel  = line.channel,
        pitch    = line.pitch,
        startQN  = line.startQN,
        endQN    = fim,
        rivals   = line.rivals,
      }
    end
  end
  return out
end

--- Fecha a linha de um controle que apagou.
--  @param byRule true quando quem apagou foi uma regra de grupo
function Recorder.noteOff(rec, element, qn, byRule)
  local tag = element.tag
  local line = tag and rec.open[tag]
  if not line then return {} end
  rec.open[tag] = nil

  local g = rec.gridQN
  local endQN = Recorder.snap(rec, qn)

  -- Uma linha nunca pode sair com comprimento zero: se você liga e
  -- desliga dentro do mesmo quadradinho, ela viraria invisível.
  local minEnd = line.startQN + g * Recorder.MIN_LENGTH_GRIDS
  if endQN < minEnd then endQN = minEnd end

  local intents = {}

  -- A nota curta de desligar só existe quando FOI VOCÊ quem desligou.
  -- Se foi regra de grupo, o Lumikit já desligou sozinho.
  local writePulse = (not byRule) and (not line.momentary)

  -- A linha vai até o instante do desligamento, sem folga: a nota que
  -- desliga começa exatamente onde a linha termina.
  local lineEnd = endQN - g * Recorder.GAP_GRIDS
  if line.limitQN and lineEnd > line.limitQN then lineEnd = line.limitQN end
  if lineEnd <= line.startQN then lineEnd = line.startQN + g * 0.5 end

  -- A nota já existe desde o acionamento: aqui só se define o fim dela.
  intents[#intents + 1] = {
    kind     = 'update',
    live     = element.tag,
    channel  = line.channel,
    pitch    = line.pitch,
    velocity = Recorder.VELOCITY,
    startQN  = line.startQN,
    endQN    = lineEnd,
    label    = line.name,
    rivals   = line.rivals,
    final    = true,
  }

  if writePulse then
    -- A nota de desligar acompanha o fim da linha. Se a linha foi
    -- limitada pelo próximo evento programado, o desligamento tem de
    -- ficar antes dele — senão cairia por cima do que já existia e
    -- desligaria o comando seguinte logo depois de ele acender.
    local pulseStart = lineEnd
    intents[#intents + 1] = {
      kind     = 'note',
      channel  = line.channel,
      pitch    = line.pitch,
      velocity = Recorder.OFF_VELOCITY,
      startQN  = pulseStart,
      endQN    = pulseStart + g * Recorder.MIN_LENGTH_GRIDS,
      label    = (line.name or '') .. ' (desliga)',
      isOff    = true,
    }
  end

  rec.written = rec.written + #intents
  return intents
end

--- Abertura de música: nota de release no primeiro quadradinho e os
--  controles já acesos a partir do segundo.
--
--  O gesto que isto reproduz: com a música parada, você marca os botões
--  com que a música começa; ao dar play, a programação já larga com eles.
--
--  O release vem ANTES por necessidade, não por estética: sem ele, o que
--  sobrou da música anterior continuaria aceso no Lumikit e se somaria à
--  abertura desta.
--
--  @param releaseEl elemento de release (pode ser nil)
--  @param armed     lista de elementos a acender
--  @param startQN   início da música, em semínimas
--  @return table intenções de escrita
function Recorder.openSong(rec, releaseEl, armed, startQN)
  local g = rec.gridQN
  local out = {}
  local base = Recorder.snap(rec, startQN)

  local temRelease = false
  if releaseEl then
    local cmd = firstNoteCommand(releaseEl)
    if cmd then
      out[#out + 1] = {
        kind     = 'note',
        channel  = cmd.channel,
        pitch    = cmd.data1,
        velocity = 127,
        startQN  = base,
        endQN    = base + g,
        label    = 'release',
      }
      temRelease = true
    end
  end

  -- A primeira célula fica RESERVADA ao release: nada mais entra nela.
  --
  -- SEM RELEASE NÃO HÁ O QUE RESERVAR. Reservar assim mesmo deixava a
  -- música abrindo uma célula depois de um vazio, e quem desligou o
  -- release no preparo não pediu um atraso — pediu que ele não fosse
  -- escrito. Vale também para o .form em que o release existe na tela
  -- mas não tem MIDI mapeado.
  Recorder.setReleaseCell(rec, temRelease and base or nil)

  -- O estado inicial começa no SEGUNDO quadradinho. O release precisa
  -- ser processado antes, senão apagaria o que acabou de ser aceso.
  local from = temRelease and (base + g) or base
  for _, element in ipairs(armed or {}) do
    local cmd = firstNoteCommand(element)
    if cmd and element.tag then
      rec.open[element.tag] = {
        startQN   = from,
        rivals    = element.rivalPitches,
        channel   = cmd.channel,
        pitch     = cmd.data1,
        velocity  = Recorder.VELOCITY,
        momentary = element.momentary == true,
        name      = element.text,
      }
      -- A nota nasce já: assim o estado inicial aparece na timeline no
      -- instante do play, e não só quando o botão for desligado.
      out[#out + 1] = {
        kind     = 'note',
        live     = element.tag,
        channel  = cmd.channel,
        pitch    = cmd.data1,
        velocity = Recorder.VELOCITY,
        startQN  = from,
        endQN    = from + g,
        label    = element.text,
        rivals   = element.rivalPitches,
      }
    end
  end

  return out
end

--- Há linha aberta para este controle?
function Recorder.isOpen(rec, tag)
  return rec.open[tag] ~= nil
end

--- Reabre linhas para os controles acesos, a partir de um ponto.
--
--  Usado no "punch in": as notas que atravessavam o ponto foram cortadas
--  ali, e aqui o gravador assume a continuação delas. A luz não muda; o
--  que muda é quem passa a ser dono do trecho dali para frente.
--
--  @param elements lista de elementos acesos
--  @return table intenções de escrita
--- @param starts opcional: tag -> início da nota já existente, em QN.
--                 Quando informado, a linha CONTINUA a nota existente em
--                 vez de começar outra no ponto do punch.
function Recorder.resume(rec, elements, qn, starts)
  local out = {}
  local base = Recorder.snap(rec, qn)

  for _, element in ipairs(elements or {}) do
    local cmd = firstNoteCommand(element)
    if cmd and element.tag and not rec.open[element.tag] then
      -- Continua a nota existente, se houver. Começar outra aqui
      -- picotaria a linha, e cada pedaço vira um Note On que alterna o
      -- controle no Lumikit — o botão apagaria no meio da música.
      local inicio = (starts and starts[element.tag]) or base
      local adotada = (starts and starts[element.tag]) ~= nil

      rec.open[element.tag] = {
        startQN   = inicio,
        adopted   = adotada,
        rivals    = element.rivalPitches,
        channel   = cmd.channel,
        pitch     = cmd.data1,
        velocity  = Recorder.VELOCITY,
        momentary = element.momentary == true,
        name      = element.text,
      }
      -- Nota ADOTADA não gera escrita: ela já está na timeline, e
      -- reescrevê-la criaria uma segunda nota no mesmo lugar.
      if not adotada then
        out[#out + 1] = {
          kind     = 'note',
          live     = element.tag,
          channel  = cmd.channel,
          pitch    = cmd.data1,
          velocity = Recorder.VELOCITY,
          startQN  = inicio,
          endQN    = inicio + rec.gridQN,
          label    = element.text,
          -- SEM rivais: retomar o estado não pode apagar o que já está
          -- gravado adiante para as outras cores do grupo.
        }
      end
    end
  end

  return out
end

--- Encerra uma linha porque um evento JÁ GRAVADO assumiu o controle.
--
--  Diferente de noteOff: aqui não se escreve nada além do fim da linha.
--  O evento que assumiu já existe na timeline, e reescrevê-lo apagaria
--  o que vem depois dele.
function Recorder.yield(rec, tag, qn)
  local line = rec.open[tag]
  if not line then return {} end
  rec.open[tag] = nil

  local fim = Recorder.snap(rec, qn)
  if fim <= line.startQN then fim = line.startQN + rec.gridQN end

  return { {
    kind    = 'update',
    live    = tag,
    channel = line.channel,
    pitch   = line.pitch,
    startQN = line.startQN,
    endQN   = fim,
    final   = true,
  } }
end

--- Fecha todas as linhas abertas. Usado ao parar o play ou ao desligar
--  a gravação: sem isso, as linhas ficariam abertas e nada seria escrito.
function Recorder.closeAll(rec, qn, elementsByTag)
  local intents = {}
  local tags = {}
  for tag in pairs(rec.open) do tags[#tags + 1] = tag end
  table.sort(tags)

  for _, tag in ipairs(tags) do
    local element = elementsByTag and elementsByTag[tag]
    if element then
      for _, it in ipairs(Recorder.noteOff(rec, element, qn, true)) do
        intents[#intents + 1] = it
      end
    else
      rec.open[tag] = nil
    end
  end
  return intents
end

--- Nota avulsa, para gravação com o transporte parado.
--
--  Com a música parada o tempo não anda, então uma linha nunca cresceria.
--  Cada clique escreve uma nota de um quadradinho no cursor de edição.
function Recorder.stepNote(rec, element, qn)
  local cmd = firstNoteCommand(element)
  if not cmd then return {} end

  local start = Recorder.snap(rec, qn)
  rec.written = rec.written + 1
  return { {
    kind     = 'note',
    channel  = cmd.channel,
    pitch    = cmd.data1,
    velocity = Recorder.VELOCITY,
    startQN  = start,
    endQN    = start + rec.gridQN * Recorder.MIN_LENGTH_GRIDS,
    label    = element.text,
  } }
end

--- Movimento de fader.
--  Sem encaixe na grade: a curva precisa ficar contínua.
function Recorder.fader(rec, element, qn, value)
  local cmd = firstCCCommand(element)
  if not cmd then return {} end

  rec.written = rec.written + 1
  return { {
    kind    = 'cc',
    channel = cmd.channel,
    cc      = cmd.data1,
    value   = value,
    qn      = qn,
    label   = element.text,
  } }
end

return Recorder
]=], "@core/recorder.lua"))(...)
end

-- ============================ core.curve
package.preload["core.curve"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/curve.lua

  Simplificação dos pontos gravados de um fader.

  REGRA DE ARQUITETURA:
    Lua puro. Nunca pode referenciar `reaper` nem `ImGui`.

  ------------------------------------------------------------------
  O PROBLEMA
  ------------------------------------------------------------------
  Arrastar um fader por dois segundos gera dezenas de leituras. Gravar
  todas produz uma automação "travada": uma escada de degraus minúsculos
  que reproduz o tremor da mão, não a intenção do movimento.

  Apagar quase tudo também não serve — perde-se o desenho do gesto.

  ------------------------------------------------------------------
  A SOLUÇÃO
  ------------------------------------------------------------------
  Douglas–Peucker: mantém os pontos que definem a FORMA da curva e
  descarta os que estão sobre a linha entre eles.

  Um movimento simples de subida vira dois pontos — começo e fim. Um
  movimento que sobe, para e desce vira três, preservando o pico. O
  gesto é reconhecido, o tremor some.

  Os pontos que restam recebem curva "slow start/end", que liga um ao
  outro com uma rampa em S em vez de um degrau. É isso que dá o
  movimento natural: a interpolação faz o trabalho que os pontos
  intermediários faziam, sem o aspecto quadrado.
------------------------------------------------------------------------]]

local Curve = {}

--- Distância vertical máxima, em unidades de CC, para um ponto ser
--  considerado "em cima da linha" e portanto descartável.
--
--  3 de 127 é cerca de 2%: abaixo disso o olho não vê diferença na luz,
--  e o que sobra é tremor de mão.
--  12 de 127 é cerca de 10%. Com a tolerância antiga (3), uma subida
--  feita à mão gerava pontos intermediários que o usuário não pediu.
--
--  O gesto típico é "saí daqui e cheguei ali": dois pontos. Só uma
--  inversão de verdade — subir e depois descer — sobrevive e vira três.
Curve.TOLERANCE = 12

--- Distância perpendicular de um ponto à reta entre dois outros.
local function distanceToLine(p, a, b)
  local dx, dy = b.qn - a.qn, b.value - a.value
  if math.abs(dx) < 1e-9 and math.abs(dy) < 1e-9 then
    return math.abs(p.value - a.value)
  end

  -- Projeção do ponto sobre a reta, no eixo do tempo.
  local t = ((p.qn - a.qn) * dx + (p.value - a.value) * dy) / (dx * dx + dy * dy)
  if t < 0 then t = 0 elseif t > 1 then t = 1 end

  local projQN    = a.qn + t * dx
  local projValue = a.value + t * dy

  -- Só o desvio em VALOR importa: um ponto adiantado no tempo mas no
  -- mesmo nível não muda a forma da automação.
  local _ = projQN
  return math.abs(p.value - projValue)
end

--- Douglas–Peucker sobre um trecho.
local function simplifySegment(points, first, last, tolerance, keep)
  if last <= first + 1 then return end

  local maxDist, maxIndex = -1, nil
  for i = first + 1, last - 1 do
    local d = distanceToLine(points[i], points[first], points[last])
    if d > maxDist then maxDist, maxIndex = d, i end
  end

  if maxDist > tolerance and maxIndex then
    keep[maxIndex] = true
    simplifySegment(points, first, maxIndex, tolerance, keep)
    simplifySegment(points, maxIndex, last, tolerance, keep)
  end
end

--- Reduz uma sequência de leituras aos pontos que definem a forma.
--
--  @param points table { { qn = número, value = 0..127 }, ... }
--  @param tolerance opcional, em unidades de CC
--  @return table os pontos preservados, na ordem original
function Curve.simplify(points, tolerance)
  if type(points) ~= 'table' or #points == 0 then return {} end
  if #points <= 2 then return points end

  tolerance = tolerance or Curve.TOLERANCE

  local keep = { [1] = true, [#points] = true }
  simplifySegment(points, 1, #points, tolerance, keep)

  local out = {}
  for i = 1, #points do
    if keep[i] then out[#out + 1] = points[i] end
  end
  return out
end

--- Prepara os pontos de um movimento para virar automação.
--
--  Além de simplificar, resolve dois casos que a simplificação sozinha
--  não trata:
--
--    Movimento SEM mudança real (a mão tremeu mas o valor é o mesmo):
--    vira um ponto só. Dois pontos idênticos não descrevem movimento
--    nenhum e só poluem a linha.
--
--    Pontos colados no tempo: leituras separadas por menos de meio
--    quadradinho viram uma só, com o último valor. Automação com dois
--    pontos no mesmo lugar é ambígua.
--
--  @param gridQN tamanho do quadradinho, para o espaçamento mínimo
--  @return table pontos finais
function Curve.polish(points, gridQN, tolerance)
  local simples = Curve.simplify(points, tolerance)
  if #simples == 0 then return {} end

  local minimo = (gridQN or 0.25) * 0.5

  local out = { simples[1] }
  for i = 2, #simples do
    local p = simples[i]
    local anterior = out[#out]

    if p.qn - anterior.qn < minimo then
      -- Perto demais: substitui o anterior, mantendo o valor mais novo.
      out[#out] = { qn = anterior.qn, value = p.value }
    else
      out[#out + 1] = p
    end
  end

  -- Movimento que começa e termina no mesmo valor, sem picos: não houve
  -- movimento algum.
  if #out == 2 and out[1].value == out[2].value then
    return { out[2] }
  end

  return out
end

--- Reduz um GESTO a dois pontos: onde começou e onde parou.
--
--  É o que a automação precisa. As dezenas de leituras do meio serviram
--  para o Lumikit acompanhar o movimento ao vivo; para o arquivo, o que
--  importa é de onde saiu e aonde chegou, ligados pela curva slow
--  start/end. O resto vira ruído na linha e deixa o movimento travado.
--
--  Se o valor não mudou, devolve um ponto só: não houve movimento.
--
--  @return table um ou dois pontos
function Curve.gesture(points)
  if type(points) ~= 'table' or #points == 0 then return {} end

  local primeiro = points[1]
  local ultimo   = points[#points]

  if primeiro.value == ultimo.value then
    return { ultimo }
  end

  return { primeiro, ultimo }
end

--- Quantos pontos foram economizados, para exibir no registro.
function Curve.describe(antes, depois)
  return ('%d leitura(s) -> %d ponto(s)'):format(antes, depois)
end

--- Em quantos pedaços dividir um trecho de curva, PELO TAMANHO DELE na
--  tela.
--
--  A rampa entre dois pontos de automação não é reta (ver ccValuesAt),
--  então ela é desenhada em pedacinhos. O número era fixo em doze — e
--  doze pedaços num trecho de três pixels são onze linhas invisíveis.
--  Numa automação densa, com a lista de faixas ao lado do .form e
--  "todos" ligado, isso vira milhares de segmentos por quadro que
--  ninguém pode ver.
--
--  Um pedaço a cada quatro pixels é mais do que o olho separa numa
--  curva suave, e o teto de doze mantém o desenho de antes nos trechos
--  largos, que são os únicos em que a curvatura aparece.
--
--  @param dx, dy  o tamanho do trecho na tela, em pixels
--  @param teto    máximo de pedaços (padrão 12)
function Curve.cortes(dx, dy, teto)
  teto = teto or 12
  local maior = math.max(math.abs(dx or 0), math.abs(dy or 0))
  local n = math.floor(maior / 4)
  if n < 1 then n = 1 end
  if n > teto then n = teto end
  return n
end

return Curve
]=], "@core/curve.lua"))(...)
end

-- ============================ core.fkeys
package.preload["core.fkeys"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/fkeys.lua

  Atalhos F1-F12 DEFINIDOS PELO USUÁRIO dentro do LumiBridge — não vêm
  do .form. O Lumikit Show reserva A-Z para o mapeamento dele próprio
  (ver core/form_parser.lua, <keyboard>); F1-F12 ficam livres, e o
  próprio editor do Lumikit não permite atribuí-las lá.

  REGRA DE ARQUITETURA:
    Lua puro. Nunca pode referenciar `reaper` nem `ImGui`. A leitura e
    escrita em disco (ExtState do REAPER) fica em ui/window.lua, que é
    quem sabe falar com o REAPER; este módulo só entende o FORMATO do
    mapa código-de-tecla -> tag de controle.

  FORMATO DE SERIALIZAÇÃO
    "112=80,113=91"  ->  { [112] = 80, [113] = 91 }
    Texto simples em vez de algo tipo JSON: o projeto não tem (nem
    precisa de) um parser de JSON só para isto.
------------------------------------------------------------------------]]

local FKeys = {}

-- Códigos de tecla virtual (mesmo espaço usado pelo .form: ver
-- Compat.keyFromCode) de F1 a F12, em ordem.
FKeys.CODES = { 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123 }

--- Nome legível de um código de tecla F (112..123 -> "F1".."F12").
--  @return string, ou nil se o código não for F1-F12.
function FKeys.label(code)
  code = tonumber(code)
  if not code or code < 112 or code > 123 then return nil end
  return 'F' .. (code - 111)
end

--- Serializa o mapa {código = tag} num texto compacto, pronto para
--  guardar no ExtState. Só entram os 12 códigos válidos de F1-F12, na
--  ORDEM de FKeys.CODES — determinístico, então o mesmo mapa sempre
--  produz o mesmo texto (importante para comparação/teste).
function FKeys.encode(map)
  if not map then return '' end
  local partes = {}
  for _, code in ipairs(FKeys.CODES) do
    local tag = map[code]
    if tag then partes[#partes + 1] = code .. '=' .. tag end
  end
  return table.concat(partes, ',')
end

--- Lê de volta o texto produzido por FKeys.encode.
--  Entradas malformadas ou fora de F1-F12 são ignoradas em silêncio: um
--  ExtState corrompido não pode travar a abertura do LumiBridge.
--  @return table {código = tag}
function FKeys.decode(texto)
  local map = {}
  if not texto or texto == '' then return map end

  local validos = {}
  for _, code in ipairs(FKeys.CODES) do validos[code] = true end

  for par in texto:gmatch('[^,]+') do
    local c, t = par:match('^(%d+)=(%d+)$')
    c, t = tonumber(c), tonumber(t)
    if c and t and validos[c] then map[c] = t end
  end
  return map
end

return FKeys
]=], "@core/fkeys.lua"))(...)
end

-- ============================ core.fadergroups
package.preload["core.fadergroups"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/fadergroups.lua

  Grupos de fader por tecla numérica (1..9, depois 0).

  Por que existe:
    Segurando a tecla do grupo, a roda do mouse em QUALQUER lugar da tela
    move junto todos os faders daquele grupo — sem precisar estar em cima
    de nenhum fader específico. Cada grupo tem um modo:

      'diff' — cada fader anda o mesmo passo da roda, preservando a
               diferença (proporção) que já havia entre eles.
      'same' — todos terminam no mesmo valor.

    Um fader pode pertencer a mais de um grupo ao mesmo tempo. Os grupos
    são por TELA (freeFormHash), como os F1-F12 — ver core/fkeys.lua, que
    segue a mesma ideia de persistência.

    Puro Lua, sem reaper/ImGui: mesma regra do resto de core/. A leitura
    de teclado e a persistência via ExtState ficam em ui/window.lua.
------------------------------------------------------------------------]]

local FaderGroups = {}

-- Ordem de exibição e de teclas: 1..9 primeiro, depois 0 (como num
-- teclado numérico comum).
FaderGroups.NUMBERS = { '1', '2', '3', '4', '5', '6', '7', '8', '9', '0' }

-- Código de tecla virtual do Windows para cada dígito — os mesmos
-- valores que o .form usa nos seus próprios atalhos (ver
-- core/form_parser.lua e Compat.keyFromCode): dígitos 0..9 são 48..57.
FaderGroups.CODES = {
  ['1'] = 49, ['2'] = 50, ['3'] = 51, ['4'] = 52, ['5'] = 53,
  ['6'] = 54, ['7'] = 55, ['8'] = 56, ['9'] = 57, ['0'] = 48,
}

FaderGroups.MODE_DIFF = 'diff'
FaderGroups.MODE_SAME = 'same'

--- Cria um grupo vazio, no modo padrão (mantém a diferença), DESLIGADO.
--
--  Nasce inativo de propósito: um grupo que o usuário ainda não montou
--  não deve começar a responder à roda no instante em que o primeiro
--  fader for marcado. Ligar é um ato explícito, na chave "Ativo".
--
--  Note a assimetria com decode(): lá, um grupo lido de um ExtState
--  SEM o campo `ativo` (formato antigo) volta LIGADO — porque aquilo
--  foi configurado por alguém numa versão em que grupo configurado
--  sempre respondia, e desligá-lo na migração mudaria, sem avisar, o
--  comportamento de um grupo que já estava em uso.
function FaderGroups.empty()
  return { mode = FaderGroups.MODE_DIFF, tags = {}, ativo = false }
end

--- Serializa os grupos para uma string compacta, para guardar no
--  ExtState. Formato: "num:modo:ativo:tag,tag,tag;num:modo:ativo:tag;..."
--  modo: 0 = diff, 1 = same. ativo: 0 = desligado, 1 = ligado.
--  Grupos vazios não entram no texto.
function FaderGroups.encode(groups)
  if not groups then return '' end
  local partes = {}
  for _, num in ipairs(FaderGroups.NUMBERS) do
    local g = groups[num]
    if g and g.tags and #g.tags > 0 then
      local modoNum = (g.mode == FaderGroups.MODE_SAME) and 1 or 0
      local ativoNum = (g.ativo == false) and 0 or 1
      partes[#partes + 1] =
        ('%s:%d:%d:%s'):format(num, modoNum, ativoNum, table.concat(g.tags, ','))
    end
  end
  return table.concat(partes, ';')
end

--- Reconstrói os grupos a partir do texto salvo.
--  Tolerante a lixo: uma entrada malformada é ignorada, sem derrubar as
--  demais nem o resto do carregamento — mesma postura de FKeys.decode.
--
--  Aceita os DOIS formatos: o atual, "num:modo:ativo:tags", e o
--  anterior a este campo "ativo" existir, "num:modo:tags" — sem isso,
--  grupos já salvos por uma versão anterior sumiriam na primeira
--  leitura desta.
function FaderGroups.decode(text)
  local groups = {}
  if not text or text == '' then return groups end

  for entrada in text:gmatch('[^;]+') do
    local num, modoTxt, ativoTxt, tagsTxt =
      entrada:match('^([^:]+):([^:]+):([01]):(.*)$')
    if not num then
      num, modoTxt, tagsTxt = entrada:match('^([^:]+):([^:]+):(.*)$')
      ativoTxt = '1'
    end
    if num and modoTxt and FaderGroups.CODES[num] then
      local g = {
        mode = (modoTxt == '1') and FaderGroups.MODE_SAME or FaderGroups.MODE_DIFF,
        ativo = (ativoTxt ~= '0'),
        tags = {},
      }
      for tagTxt in (tagsTxt or ''):gmatch('[^,]+') do
        local tag = tonumber(tagTxt)
        if tag then g.tags[#g.tags + 1] = tag end
      end
      if #g.tags > 0 then groups[num] = g end
    end
  end

  return groups
end

--- Calcula os arrastos SINTÉTICOS que o arrasto de um fader do grupo
--  gera para os OUTROS membros — usado por ui/window.lua pra fazer o
--  arrasto valer pro grupo inteiro, não só a roda (Session.wheelFader /
--  Session.setFaderTarget cobrem a roda; isto aqui é o equivalente para
--  o arrasto direto do mouse).
--
--  Puro Lua: em vez de depender do Session (que é core, mas trata de
--  estado vivo), recebe o valor atual de qualquer fader por uma função
--  — `currentValue(tag) -> 0..1` — e devolve só dados, sem tocar em
--  nada. Quem chama decide o que fazer com o resultado (ui/window.lua
--  aplica via Session.setFader e manda pro MIDI/gravação).
--
--  @param draggedEvents lista de { tag, value } — arrastos REAIS deste
--                        quadro (o valor já é o alvo, calculado pela
--                        posição do mouse sobre ESSE fader)
--  @param heldNow        num -> true/false, a tecla do grupo está
--                        segurada neste quadro?
--  @param groups         num -> { mode, tags } (ver FaderGroups.decode)
--  @param currentValue   function(tag) -> 0..1, valor atual do fader
--  @return lista de { tag, value } sintéticos, um por membro afetado
function FaderGroups.dragExtras(draggedEvents, heldNow, groups, currentValue)
  local extras = {}
  if not draggedEvents or not heldNow or not groups or not currentValue then
    return extras
  end

  for _, ev in ipairs(draggedEvents) do
    for _, num in ipairs(FaderGroups.NUMBERS) do
      if heldNow[num] then
        local g = groups[num]
        if g and g.tags and g.ativo ~= false then
          local pertence = false
          for _, t in ipairs(g.tags) do
            if t == ev.tag then pertence = true end
          end

          if pertence then
            local antes = currentValue(ev.tag) or 0
            local delta = ev.value - antes

            for _, outroTag in ipairs(g.tags) do
              if outroTag ~= ev.tag then
                local novo
                if g.mode == FaderGroups.MODE_SAME then
                  novo = ev.value
                else
                  novo = (currentValue(outroTag) or 0) + delta
                end
                if novo < 0 then novo = 0 elseif novo > 1 then novo = 1 end
                extras[#extras + 1] = { tag = outroTag, value = novo }
              end
            end
          end
        end
      end
    end
  end

  return extras
end

return FaderGroups
]=], "@core/fadergroups.lua"))(...)
end

-- ============================ core.lanes
package.preload["core.lanes"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/lanes.lua

  Monta as FAIXAS DE PROGRAMAÇÃO: o que está gravado nesta música,
  organizado por controle do .form em vez de por altura MIDI.

  POR QUE ISTO EXISTE
    Para conferir uma gravação é preciso abrir o editor MIDI do REAPER —
    e num monitor só isso significa perder a tela do LumiBridge de vista.
    Pior: lá se lê "nota 59", não "VERM PURO". O REAPER não tem como
    saber que aquela altura é o vermelho; o .form sabe.

    Estas faixas mostram a mesma programação com o NOME e a COR de cada
    controle, na ordem em que ele aparece na tela. É o editor MIDI que
    faltava para iluminação.

  SEM REAPER E SEM ImGui, como todo core/. Aqui se decide o que vira
  linha, em que ordem, e o que o mouse acertou; desenhar e escrever na
  timeline é com quem chama.
------------------------------------------------------------------------]]

local Lanes = {}

--- Fração da largura de um bloco que conta como "borda", para pegar e
--  arrastar o início ou o fim.
--
--  Em FRAÇÃO, não em pixels fixos: num bloco curto, uma borda de 6px
--  cobriria o bloco inteiro e nunca daria para pegar o meio dele.
Lanes.BORDA_FRACAO = 0.25

--- Largura mínima da borda, em segundos de tempo de tela.
--  Complementa a fração: num bloco longo, 25% de cada lado seria uma
--  área de pega enorme e imprecisa.
Lanes.BORDA_MAX = 0.35

--- Altura da borda de pega, no mínimo, para blocos muito curtos não
--  ficarem impossíveis de acertar.
Lanes.BORDA_MIN = 0.04

--- Paleta das faixas, na ordem em que é distribuída pelos grupos.
--
--  POR QUE NÃO USAR A COR DO CONTROLE. No .form de referência todos os
--  botões têm o MESMO fundo (135,135,135) — a identidade visual deles
--  está no ícone, não na cor. Pintar as faixas com a cor do controle
--  produz uma tela inteira de cinza, que foi exatamente o que aconteceu.
--
--  Escolhida para o fundo escuro das faixas e para vizinhas serem
--  distinguíveis: cores adjacentes na lista nunca são do mesmo matiz,
--  porque grupos próximos na tela recebem posições próximas aqui.
Lanes.CORES = {
  { r = 232, g =  90, b =  90 },   -- vermelho
  { r =  80, g = 150, b = 240 },   -- azul
  { r =  95, g = 200, b = 130 },   -- verde
  { r = 240, g = 180, b =  70 },   -- âmbar
  { r = 175, g = 140, b = 240 },   -- roxo
  { r =  90, g = 205, b = 215 },   -- ciano
  { r = 235, g = 120, b = 180 },   -- rosa
  { r = 240, g = 140, b =  80 },   -- laranja
  { r = 175, g = 205, b =  90 },   -- limão
  { r = 120, g = 165, b = 205 },   -- azul-aço
}

--- Cor dos faders: um neutro frio, fora da paleta dos grupos.
--  Fader não disputa com botão nenhum; dar-lhe uma cor de grupo sugeriria
--  uma exclusividade que não existe.
Lanes.COR_FADER = { r = 150, g = 170, b = 195 }

--- Cor de quem não pertence a grupo nenhum.
Lanes.COR_SOLTO = { r = 130, g = 138, b = 150 }

--- Uma cor por CONTROLE, derivada do grupo "apenas um ativo" dele.
--
--  Os grupos são DECLARADOS no .form (ver core/rules.lua), não inferidos
--  da geometria: é informação que o arquivo traz, não palpite nosso. E é
--  a informação certa para uma faixa de tempo — os membros de um grupo
--  exclusivo se substituem, então uma troca de cor na linha do tempo é
--  exatamente uma troca de comando.
--
--  A ordem das cores segue a primeira aparição de cada grupo NA TELA, e
--  não a ordem em que a tabela de regras foi lida: `pairs` não tem ordem
--  garantida, e sem isto as cores mudariam de lugar entre uma abertura e
--  outra do mesmo arquivo.
--
--  @return table tag -> cor
function Lanes.palette(layout, ruleIndex)
  local cores = {}
  if not layout or not ruleIndex then return cores end

  -- Um controle pode estar em mais de um grupo exclusivo. Vale o de
  -- MENOR chave, escolhido com a lista ordenada para a decisão ser a
  -- mesma em toda execução.
  local chaves = {}
  for chave in pairs(ruleIndex.exclusive or {}) do chaves[#chaves + 1] = chave end
  table.sort(chaves)

  local grupoDe = {}
  for _, chave in ipairs(chaves) do
    for _, tag in ipairs(ruleIndex.exclusive[chave]) do
      if not grupoDe[tag] then grupoDe[tag] = chave end
    end
  end

  local ordem, vistos = {}, {}
  for _, e in ipairs(layout.elements or {}) do
    local k = e.tag and grupoDe[e.tag]
    if k and not vistos[k] then
      vistos[k] = true
      ordem[#ordem + 1] = k
    end
  end

  local porGrupo = {}
  for i, k in ipairs(ordem) do
    porGrupo[k] = Lanes.CORES[(i - 1) % #Lanes.CORES + 1]
  end

  for _, e in ipairs(layout.elements or {}) do
    if e.tag then cores[e.tag] = porGrupo[grupoDe[e.tag]] end
  end
  return cores, grupoDe
end

--- Trechos dos RIVAIS de uma linha: os outros controles do mesmo grupo
--  "apenas um ativo".
--
--  Eles não podem soar ao mesmo tempo que este — não é preferência
--  visual: num grupo exclusivo o Lumikit desliga o anterior quando o
--  próximo entra. Dois trechos do grupo sobrepostos são uma promessa que
--  a reprodução não cumpre, e quem programou olhando a tela vai ao palco
--  com uma expectativa errada.
--
--  @return table { { t0, t1 }, ... } ordenado por t0
function Lanes.rivais(linhas, linha)
  local out = {}
  if not linha or not linha.grupo then return out end

  for _, l in ipairs(linhas or {}) do
    if l ~= linha and l.grupo == linha.grupo and l.tipo == 'botao' then
      for _, b in ipairs(l.blocos) do
        -- O pulso de desligar conta junto: ele também é uma nota, e
        -- encostar nele é encostar no rival.
        out[#out + 1] = { t0 = b.t0, t1 = (b.fecho and b.fecho.t1) or b.t1 }
      end
    end
  end
  table.sort(out, function(a, b) return a.t0 < b.t0 end)
  return out
end

--- Até onde um trecho pode ir sem entrar num rival.
--
--  @param rivais  saída de Lanes.rivais
--  @param de      onde o trecho começa
--  @param ate     onde ele iria
--  @return o `ate` limitado
function Lanes.limiteAte(rivais, de, ate)
  for _, r in ipairs(rivais or {}) do
    if r.t0 >= de and r.t0 < ate then ate = r.t0 end
  end
  return ate
end

--- Primeira nota de um elemento, se houver.
local function alturaDe(element)
  for _, cmd in ipairs(element.commands or {}) do
    if (cmd.status & 0xF0) == 0x90 then return cmd.data1, cmd.channel end
  end
  return nil
end

--- Primeiro Control Change de um elemento, se houver.
local function ccDe(element)
  for _, cmd in ipairs(element.commands or {}) do
    if (cmd.status & 0xF0) == 0xB0 then return cmd.data1, cmd.channel end
  end
  return nil
end

--- Dobra o PULSO DE DESLIGAR dentro do bloco que ele fecha.
--
--  Ao desligar um toggle, a gravação escreve a nota longa (o tempo em
--  que o controle ficou aceso) e, colada nela, uma nota curta de uma
--  célula — é ela que efetivamente apaga a luz (ver Recorder.noteOff).
--
--  O editor MIDI mostra as duas como notas irmãs, e é preciso conhecer a
--  convenção para ler aquilo. Aqui a curta deixa de ser um bloco à parte
--  e vira uma marca de FIM no bloco que ela fecha: sem largura extra,
--  sem parecer sujeira, e distinguindo de relance um trecho que VOCÊ
--  desligou de um que acabou por outro motivo — regra de grupo, fim da
--  gravação, fim da música. Essa diferença existe na gravação e não é
--  visível em lugar nenhum hoje.
--
--  O reconhecimento é geométrico porque tem de ser: as duas notas saem
--  com a mesma velocity, de propósito (ver Recorder.VELOCITY), então não
--  há como distingui-las pelo conteúdo. Cola no fim da anterior e dura
--  uma célula: é o pulso.
local function dobrarFechos(blocos, celula)
  if not celula or celula <= 0 then return blocos end
  local folga = celula * 0.25
  local out = {}
  for _, b in ipairs(blocos) do
    local ant = out[#out]
    if ant and not ant.fecho
       and math.abs(b.t0 - ant.t1) < folga
       and math.abs((b.t1 - b.t0) - celula) < folga then
      ant.fecho = { t0 = b.t0, t1 = b.t1 }
    else
      out[#out + 1] = b
    end
  end
  return out
end

--- Monta as linhas a partir do que foi lido da timeline.
--
--  A ORDEM É A DO EDITOR MIDI DO REAPER, e é pedido explícito: quem
--  alterna entre as duas telas reconhece a mesma sequência nas duas, sem
--  reprocurar cada controle.
--
--  Isso significa PIANO ROLL: notas ordenadas por altura, a mais grave
--  embaixo, exatamente como o teclado desenhado na lateral do editor. E
--  as faixas de CC depois de todas as notas, por número de controlador —
--  também como lá, onde as CC lanes ficam abaixo do piano roll.
--
--  A ordem do .form foi o primeiro critério e tinha um argumento a favor
--  (a linha do vermelho sempre no mesmo lugar), mas perde para este: a
--  ordem da tela só ajuda quem olha só esta tela, e o ponto destas
--  faixas é justamente não precisar do editor — quando ele for preciso,
--  as duas listas têm de bater.
--
--  Controles SEM evento nesta música ficam de fora por padrão: numa tela
--  com duzentos botões, mostrar todos afogaria os cinco que interessam.
--
--  O QUE O PREPARO ESCREVEU NÃO CONTA COMO PROGRAMAÇÃO.
--
--  O preparo põe dois pontos de automação em CADA fader do .form e uma
--  nota de release na primeira célula — sempre, em toda música, mexendo
--  você neles ou não. Contá-los como "controle desta música" enche a
--  lista de linhas que ninguém programou: num .form com cinco masters,
--  são seis linhas de ruído antes da primeira que interessa.
--
--  A distinção é objetiva. Fader: o preparo deixa EXATAMENTE dois
--  pontos, e qualquer gesto deixa mais. Release: o preparo deixa um
--  bloco só, na primeira célula — um release apertado no meio da música
--  é outra coisa, e esse aparece.
--
--  @param layout    o .form carregado (dá a ordem e as cores)
--  @param session   a sessão (diz quem é fader)
--  @param eventos   { notas = { {pitch, t0, t1} }, ccs = { {cc, t, valor} } }
--  @param todos     mostrar também o que ninguém programou
--  @param contexto  { inicio = início da música, celula = grade em segundos,
--                     releaseTag = tag do Release All }
--  @return table linhas, integer quantas foram escondidas
function Lanes.build(layout, session, eventos, todos, contexto)
  local linhas = {}
  if not layout or not session then return linhas end

  -- Índices por altura e por CC, montados UMA vez. Sem isto seria uma
  -- varredura de todas as notas por elemento, e numa música cheia com
  -- uma tela grande isso é multiplicação pura.
  local porAltura, porCC = {}, {}
  for _, n in ipairs(eventos and eventos.notas or {}) do
    local lista = porAltura[n.pitch]
    if not lista then lista = {} porAltura[n.pitch] = lista end
    lista[#lista + 1] = n
  end
  for _, c in ipairs(eventos and eventos.ccs or {}) do
    local lista = porCC[c.cc]
    if not lista then lista = {} porCC[c.cc] = lista end
    lista[#lista + 1] = c
  end

  contexto = contexto or {}

  --- Isto é só o que o preparo escreveu, sem nada seu por cima?
  --
  --  Vale também para o "ocultar CC": o botão da barra esconde as faixas
  --  de fader nas DUAS telas, e esconder aqui é o mesmo mecanismo de
  --  esconder o que o preparo escreveu — some da lista, entra na conta
  --  do que está oculto, e "mostrar todos" traz de volta.
  local function soODoPreparo(linha)
    if linha.tipo == 'fader' then
      if contexto.semCC then return true end
      return #linha.pontos <= 2
    end
    if contexto.releaseTag and linha.tag == contexto.releaseTag then
      local b = linha.blocos[1]
      return #linha.blocos == 1 and b
             and b.t0 < (contexto.inicio or 0) + (contexto.celula or 0) * 1.5
    end
    return false
  end

  local escondidas = 0
  -- OS NOMES, e não só a contagem. "6 ocultos" responde quantos e não
  -- responde quais — e o número muda com a música. Os controles ocultos,
  -- por definição, não estão em lugar nenhum para serem lidos.
  local nomesOcultos = {}
  local jaVisto = {}
  for _, e in ipairs(layout.elements or {}) do
    local tag = e.tag
    if tag and not jaVisto[tag] and e.commands and #e.commands > 0
       and not e.hidden then
      local ehFader = session.faderTags and session.faderTags[tag]

      if ehFader then
        local cc = ccDe(e)
        local pontos = cc and porCC[cc] or nil
        if pontos or todos then
          jaVisto[tag] = true
          table.sort(pontos or {}, function(a, b) return a.t < b.t end)
          local linha = {
            tag = tag, nome = e.text or ('#' .. tostring(tag)),
            cor = (contexto.cores and contexto.cores[tag]) or Lanes.COR_FADER,
            tipo = 'fader', cc = cc, canal = select(2, ccDe(e)),
            pontos = pontos or {}, blocos = {},
          }
          if todos or not soODoPreparo(linha) then
            linhas[#linhas + 1] = linha
          else
            escondidas = escondidas + 1
            nomesOcultos[#nomesOcultos + 1] = linha.nome
          end
        end
      else
        local pitch = alturaDe(e)
        local notas = pitch and porAltura[pitch] or nil
        if notas or todos then
          jaVisto[tag] = true
          local blocos = {}
          for _, n in ipairs(notas or {}) do
            blocos[#blocos + 1] = { t0 = n.t0, t1 = n.t1, pitch = n.pitch }
          end
          table.sort(blocos, function(a, b) return a.t0 < b.t0 end)
          blocos = dobrarFechos(blocos, contexto.celula)
          local linha = {
            tag = tag, nome = e.text or ('#' .. tostring(tag)),
            cor = (contexto.cores and contexto.cores[tag]) or Lanes.COR_SOLTO,
            grupo = contexto.grupoDe and contexto.grupoDe[tag] or nil,
            tipo = 'botao', pitch = pitch, blocos = blocos,
            -- O CANAL vem do próprio comando MIDI do controle. Cada um
            -- pode estar num canal diferente, então não é um número só
            -- para a tela inteira.
            canal = select(2, alturaDe(e)),
          }
          if todos or not soODoPreparo(linha) then
            linhas[#linhas + 1] = linha
          else
            escondidas = escondidas + 1
            nomesOcultos[#nomesOcultos + 1] = linha.nome
          end
        end
      end
    end
  end

  -- ORDENA COMO O EDITOR MIDI: notas por altura (grave embaixo), depois
  -- as CC por número. O empate cai na ordem do .form, que é a ordem em
  -- que as linhas foram montadas — estável, e nunca troca sozinha entre
  -- uma abertura e outra.
  for i, l in ipairs(linhas) do l.ordem = i end
  table.sort(linhas, function(a, b)
    if (a.tipo == 'fader') ~= (b.tipo == 'fader') then
      return b.tipo == 'fader'
    end
    if a.tipo == 'fader' then
      if (a.cc or 0) ~= (b.cc or 0) then return (a.cc or 0) < (b.cc or 0) end
    else
      if (a.pitch or 0) ~= (b.pitch or 0) then
        return (a.pitch or 0) > (b.pitch or 0)
      end
    end
    return a.ordem < b.ordem
  end)

  table.sort(nomesOcultos)
  return linhas, escondidas, nomesOcultos
end

--- O que o mouse acertou numa linha, num instante do tempo.
--
--  Devolve o bloco E QUAL PARTE dele: 'inicio', 'fim' ou 'meio'. Quem
--  desenha usa isso para trocar o cursor antes do clique — pegar a borda
--  errada e descobrir depois é o tipo de erro que custa uma gravação.
--
--  @param linha   uma linha de Lanes.build
--  @param tempo   posição em segundos
--  @param escala  segundos por pixel, para a borda ter largura constante
--                 na tela mesmo com o zoom mudando
--  @return bloco, parte  ou nil
function Lanes.hit(linha, tempo, escala)
  if not linha or linha.tipo ~= 'botao' then return nil end

  for _, b in ipairs(linha.blocos) do
    if tempo >= b.t0 and tempo <= b.t1 then
      local dur = b.t1 - b.t0
      local borda = dur * Lanes.BORDA_FRACAO
      if borda > Lanes.BORDA_MAX then borda = Lanes.BORDA_MAX end
      -- O piso é em PIXELS convertidos para tempo: uma borda de 4px vale
      -- 4px em qualquer zoom, e é isso que o dedo espera.
      local piso = math.max(Lanes.BORDA_MIN, (escala or 0) * 4)
      if borda < piso then borda = math.min(piso, dur * 0.5) end

      if tempo <= b.t0 + borda then return b, 'inicio' end
      if tempo >= b.t1 - borda then return b, 'fim' end
      return b, 'meio'
    end
  end
  return nil
end

--- Qual ponto de automação o mouse acertou, se algum.
--
--  Só pelo TEMPO, não pela distância até a curva: acertar um ponto no
--  eixo do valor exigiria mirar em algo de dois pixels, e o valor é
--  exatamente o que se quer mudar arrastando. Perto no tempo basta para
--  saber QUAL ponto é.
--
--  @param linha       linha de fader
--  @param tempo       posição do mouse, em segundos
--  @param tolerancia  em segundos (a UI converte de pixels)
--  @return indice, ponto  ou nil
function Lanes.hitPonto(linha, tempo, tolerancia)
  if not linha or linha.tipo ~= 'fader' then return nil end
  local melhor, dist
  for i, p in ipairs(linha.pontos) do
    local d = math.abs(p.t - tempo)
    if d <= (tolerancia or 0) and (not dist or d < dist) then
      melhor, dist = i, d
    end
  end
  if melhor then return melhor, linha.pontos[melhor] end
  return nil
end

--- Onde um ponto pode ir, sem passar pelos vizinhos.
--
--  A automação é uma sequência ordenada no tempo: um ponto que ultrapassa
--  o vizinho inverte a ordem, e a interpolação entre eles passa a andar
--  para trás. Trava antes de chegar, com uma folga mínima para os dois
--  não coincidirem — dois pontos no mesmo instante são um degrau que
--  ninguém pediu.
--
--  @return tempo, valor já limitados
function Lanes.moverPonto(linha, indice, tempo, valor, folga)
  folga = folga or 0.01
  local ant = linha.pontos[indice - 1]
  local seg = linha.pontos[indice + 1]
  if ant and tempo < ant.t + folga then tempo = ant.t + folga end
  if seg and tempo > seg.t - folga then tempo = seg.t - folga end
  if valor < 0 then valor = 0 elseif valor > 127 then valor = 127 end
  return tempo, math.floor(valor + 0.5)
end

--- Aplica um arrasto de borda, respeitando os limites.
--
--  REGRAS, e todas existem por um motivo prático:
--
--   - O bloco não pode inverter (fim antes do início). Um bloco invertido
--     não é nota nenhuma: o REAPER o descarta e o trabalho some.
--   - Não pode ficar menor que uma célula da grade. Nota mais curta que
--     isso não é vista pelo Lumikit — a luz nem chega a acender.
--   - Não pode passar por cima do bloco vizinho DO MESMO controle:
--     seriam duas notas sobrepostas na mesma altura, e o resultado na
--     reprodução é imprevisível.
--
--   - O PULSO DE DESLIGAR precisa caber depois do bloco. Ele ocupa uma
--     célula colada no fim (ver dobrarFechos) e vai junto quando a borda
--     direita é arrastada — foi decisão explícita: aumentar a nota à mão
--     leva o desligamento junto, enquanto regravar por cima escreve um
--     novo. Sem reservar essa célula, esticar até encostar no vizinho
--     jogaria o pulso EM CIMA dele, desligando o comando seguinte no
--     instante em que ele acende.
--
--  @param linha    a linha do bloco
--  @param bloco    o bloco a mexer
--  @param parte    'inicio' ou 'fim'
--  @param destino  novo instante, em segundos
--  @param minimo   duração mínima (uma célula da grade, em segundos)
--  @return t0, t1 já limitados
--- Cola um instante na borda de nota mais próxima, se houver uma perto.
--
--  Dois controles clicados "praticamente juntos" ficam a poucos
--  milissegundos um do outro. Acionar junto era a intenção, mas acertar
--  isso arrastando à mão, num pixel, é impossível — o ímã resolve o que
--  a mão não alcança: aproximar já basta.
--
--  CANDIDATAS SÃO AS BORDAS DE TODAS AS LINHAS, e não só as da linha
--  arrastada: o caso que motivou isto é justamente casar DUAS linhas
--  diferentes. A própria borda que está sendo puxada fica de fora, senão
--  ela colaria em si mesma e nada se moveria.
--
--  @param excluir  bloco a ignorar (o que está sendo arrastado)
--  @return o instante colado, ou o próprio destino se nada estiver perto
function Lanes.imantar(linhas, destino, tolerancia, excluir)
  if not linhas or not tolerancia or tolerancia <= 0 then return destino end
  local melhor, dist = destino, tolerancia
  for _, ln in ipairs(linhas) do
    for _, b in ipairs(ln.blocos or {}) do
      if b ~= excluir then
        for _, t in ipairs({ b.t0, b.t1 }) do
          local d = math.abs(t - destino)
          if d < dist then melhor, dist = t, d end
        end
      end
    end
  end
  return melhor
end

--- Este bloco está na seleção múltipla?
--
--  POR PROXIMIDADE, e não por igualdade de chave. A seleção é guardada
--  pelo instante em que o bloco começa, e esse número é recalculado toda
--  vez que a lista é remontada — a ida e volta segundos/tique não
--  devolve bit a bit o mesmo float.
--
--  Comparar com `==` funcionava até a primeira remontagem e falhava
--  depois, calado: pegar um bloco marcado parecia pegá-lo de FORA da
--  seleção, a seleção era descartada e o arrasto levava um bloco só.
--
--  @param sel  tabela [tag] = { [instante] = true }
function Lanes.marcada(sel, tag, t0)
  local marcados = sel and sel[tag]
  if not marcados then return false end
  if marcados[t0] then return true end
  for k in pairs(marcados) do
    if math.abs(k - t0) < 0.002 then return true end
  end
  return false
end

function Lanes.arrastar(linha, bloco, parte, destino, minimo, rivais)
  minimo = minimo or 0.05
  local t0, t1 = bloco.t0, bloco.t1
  local reserva = bloco.fecho and (bloco.fecho.t1 - bloco.fecho.t0) or 0

  -- Vizinhos imediatos, para não invadir.
  local anterior, seguinte = nil, nil
  for _, b in ipairs(linha.blocos) do
    if b ~= bloco then
      if b.t1 <= bloco.t0 and (not anterior or b.t1 > anterior.t1) then
        anterior = b
      end
      if b.t0 >= bloco.t1 and (not seguinte or b.t0 < seguinte.t0) then
        seguinte = b
      end
    end
  end

  -- MOVER O TRECHO INTEIRO, comprimento preservado.
  --
  -- O ponteiro já mostrava a mãozinha sobre o meio de um bloco e o
  -- arrasto não fazia nada: a janela só criava o gesto para as duas
  -- bordas. Prometer com o cursor e não cumprir é pior do que não
  -- oferecer.
  --
  -- `destino` é onde o INÍCIO deve cair — a janela desconta o ponto em
  -- que a mão pegou o bloco, senão ele saltaria para debaixo do ponteiro
  -- no primeiro pixel de arrasto.
  --
  -- Os limites são os mesmos das bordas, aplicados aos dois lados de uma
  -- vez: não entra no vizinho de trás, não passa por cima do da frente
  -- (nem do desligamento dele), não invade o trecho de um rival do mesmo
  -- grupo "apenas um ativo".
  if parte == 'meio' then
    local dur = t1 - t0
    t0 = destino
    if anterior and t0 < anterior.t1 then t0 = anterior.t1 end
    if t0 < 0 then t0 = 0 end
    t1 = t0 + dur

    local limite = seguinte and (seguinte.t0 - reserva) or nil
    if rivais then
      local r = Lanes.limiteAte(rivais, t0, t1) - reserva
      if not limite or r < limite then limite = r end
    end
    if limite and t1 > limite then
      t1 = limite
      t0 = t1 - dur
      -- Empurrado para trás, ainda assim não pode entrar no anterior.
      if anterior and t0 < anterior.t1 then
        t0 = anterior.t1
        t1 = t0 + dur
      end
    end
    return t0, t1
  end

  if parte == 'inicio' then
    t0 = destino
    if anterior and t0 < anterior.t1 then t0 = anterior.t1 end
    -- Recuar o início também pode entrar num rival, pelo outro lado.
    for _, r in ipairs(rivais or {}) do
      if r.t1 <= t1 and r.t1 > t0 then t0 = r.t1 end
    end
    if t0 > t1 - minimo then t0 = t1 - minimo end
  elseif parte == 'fim' then
    t1 = destino
    if seguinte and t1 > seguinte.t0 - reserva then
      t1 = seguinte.t0 - reserva
    end
    -- E NEM NO TRECHO DE UM RIVAL, que é de outra LINHA mas do mesmo
    -- grupo "apenas um ativo". Sem isto dava para esticar um trecho por
    -- cima de outro do mesmo grupo — e na reprodução o Lumikit desliga
    -- um quando o outro entra, então a tela mostrava algo que a música
    -- não faz.
    if rivais then
      t1 = Lanes.limiteAte(rivais, t0, t1) - reserva
    end
    if t1 < t0 + minimo then t1 = t0 + minimo end
  end

  return t0, t1
end

return Lanes
]=], "@core/lanes.lua"))(...)
end

-- ============================ core.historico
package.preload["core.historico"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/historico.lua

  O desfazer DAS EDIÇÕES, separado do desfazer do REAPER.

  POR QUE EXISTE
    A pilha de desfazer do REAPER é uma só, e é dele. Nossas edições
    entravam nela por Undo_BeginBlock/Undo_EndBlock — e o REAPER descarta
    em silêncio um bloco que ele julgue sem mudança. Quando isso
    acontecia, o Ctrl+Z seguinte acertava o ponto ANTERIOR: logo depois
    de gravar, a gravação inteira. Apagar dez minutos de trabalho por ter
    arrastado a borda de uma nota é inaceitável, e três tentativas de
    convencer o REAPER a registrar o bloco não resolveram.

    Então o editor passa a ter memória própria. Cada edição guarda o
    ANTES e o DEPOIS do que mexeu, e desfazer é restaurar o antes. Não
    depende do humor do REAPER, e dá exatamente o que se espera de um
    editor: uma edição, um passo.

  O QUE É UM "ESTADO"
    Este módulo não sabe. Ele recebe dois valores opacos por passo e uma
    função que sabe aplicá-los. Quem chama decide o que fotografar — na
    janela, é o MIDI dos itens da track (ver Timeline.fotografar). Assim
    a lógica de pilha fica testável no terminal, sem REAPER nenhum.

  O QUE NÃO ENTRA AQUI
    A GRAVAÇÃO. Ela é grande, é do REAPER, e o usuário já espera que um
    Ctrl+Z depois do stop a desfaça inteira. Gravar LIMPA este histórico:
    um estado fotografado antes da gravação, restaurado depois dela,
    apagaria a gravação — que é justamente o desastre que este módulo
    existe para impedir.
------------------------------------------------------------------------]]

local Historico = {}

--- Quantos passos para trás o editor lembra.
--
--  Cada passo guarda o conteúdo dos itens que mudaram. Sessenta passos
--  de uma música de porte normal ficam na casa de poucos megabytes, e
--  ninguém desfaz sessenta edições de uma sentada.
Historico.LIMITE = 60

function Historico.novo(restaurar)
  return { feitos = {}, refeitos = {}, restaurar = restaurar,
           limite = Historico.LIMITE }
end

--- Guarda uma edição já feita.
--
--  @param rotulo  o que aparece na dica do botão desfazer
--  @param antes   estado de antes da edição
--  @param depois  estado de depois
function Historico.registrar(h, rotulo, antes, depois)
  if not h or antes == nil or depois == nil then return false end

  h.feitos[#h.feitos + 1] = { rotulo = rotulo, antes = antes, depois = depois }
  while #h.feitos > (h.limite or Historico.LIMITE) do
    table.remove(h.feitos, 1)
  end

  -- UM ATO NOVO APAGA O CAMINHO DE VOLTA. É a regra de todo editor:
  -- desfiz três, editei — os três refazeres não fazem mais sentido,
  -- porque o futuro que eles reconstruíam deixou de existir.
  h.refeitos = {}
  return true
end

function Historico.podeDesfazer(h) return h ~= nil and #h.feitos > 0 end
function Historico.podeRefazer(h)  return h ~= nil and #h.refeitos > 0 end

function Historico.rotuloDesfazer(h)
  local p = h and h.feitos[#h.feitos]
  return p and p.rotulo or nil
end

function Historico.rotuloRefazer(h)
  local p = h and h.refeitos[#h.refeitos]
  return p and p.rotulo or nil
end

--- Volta um passo.
--
--  RESTAURAR PODE FALHAR: o item pode ter sido apagado por fora, o
--  projeto pode ter sido fechado. Um histórico que não consegue mais
--  aplicar seus estados é pior que histórico nenhum — o passo seguinte
--  escreveria um estado velho por cima de coisa que não é dele. Falhou,
--  esquece tudo.
--
--  @return rotulo do passo desfeito, ou nil
--  @return rotulo do passo perdido, quando a restauração falhou
function Historico.desfazer(h)
  local passo = h and h.feitos[#h.feitos]
  if not passo then return nil end

  if not h.restaurar(passo.antes) then
    Historico.limpar(h)
    return nil, passo.rotulo
  end

  table.remove(h.feitos)
  h.refeitos[#h.refeitos + 1] = passo
  return passo.rotulo
end

function Historico.refazer(h)
  local passo = h and h.refeitos[#h.refeitos]
  if not passo then return nil end

  if not h.restaurar(passo.depois) then
    Historico.limpar(h)
    return nil, passo.rotulo
  end

  table.remove(h.refeitos)
  h.feitos[#h.feitos + 1] = passo
  return passo.rotulo
end

--- Esquece tudo. Chamado quando o chão se move debaixo dos estados
--  guardados: gravação, troca de música, desfazer do próprio REAPER.
function Historico.limpar(h)
  if not h then return end
  h.feitos, h.refeitos = {}, {}
end

--- Quantos passos para trás e para frente. Só para diagnóstico e testes.
function Historico.tamanho(h)
  if not h then return 0, 0 end
  return #h.feitos, #h.refeitos
end

return Historico
]=], "@core/historico.lua"))(...)
end

-- ============================ core.licenca
package.preload["core.licenca"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/licenca.lua

  Chave de licença amarrada à máquina, sem servidor e sem internet.

  COMO FUNCIONA
    1. O programa mostra o CÓDIGO DA MÁQUINA — oito dígitos tirados do
       nome do computador, do usuário e do processador.
    2. O cliente manda esse código ao vendedor.
    3. O vendedor roda tools/gerar_chave.lua, cola o código e recebe a
       CHAVE.
    4. O cliente digita a chave. Ela vale só naquela máquina, para
       sempre, sem internet.

  POR QUE NÃO UMA LISTA DE SERIAIS
    Uma lista embutida no programa é uma lista que qualquer um lê — o
    ReaScript é distribuído em Lua legível. A chave é CALCULADA a partir
    do código da máquina: o programa sabe conferir sem guardar nenhuma.

  ATÉ ONDE ISTO PROTEGE — e vale dizer com todas as letras.

    RESOLVE o que acontece de verdade: o cliente passar a chave adiante.
    Na máquina do amigo o código é outro e a chave não encaixa.

    NÃO RESOLVE quem abrir o arquivo e arrancar a verificação. Sendo
    offline, o segredo viaja dentro do programa — é o preço de não
    depender de servidor nem de internet, que num palco é o que importa.
    Blindagem de verdade só com o núcleo compilado, que é outra obra.

  O CÓDIGO DA MÁQUINA NÃO OLHA O HARDWARE, de propósito. Trocar um pente
  de memória ou um HD não pode invalidar a licença de alguém no meio de
  um show. Nome do computador, usuário e modelo do processador mudam
  quando a pessoa formata e reinstala — aí ela pede outra chave, que é o
  comportamento certo.
------------------------------------------------------------------------]]

local Licenca = {}

-- O SEGREDO. Trocar isto invalida todas as chaves já emitidas.
--
-- Em pedaços e remontado em tempo de execução: não muda nada para quem
-- lê o código com atenção, e tira a string do alcance de quem só passa
-- um `grep` procurando por algo que pareça uma senha.
local S1, S2, S3 = 'Lm', 'bR1dg3', '::7f2a'
local function segredo() return S1 .. S3 .. S2 end

--- Espalhador de 32 bits, à moda do FNV-1a com uma volta a mais.
--
--  Não é criptografia e não finge ser. É o suficiente para que a chave
--  de uma máquina não sirva noutra e para que ninguém adivinhe uma
--  chave olhando outra.
local function mistura(texto)
  local h = 0x811C9DC5
  for i = 1, #texto do
    h = h ~ texto:byte(i)
    h = (h * 0x01000193) & 0xFFFFFFFF
    h = ((h << 13) | (h >> 19)) & 0xFFFFFFFF
  end
  -- Avalanche final: sem ela, entradas parecidas saem com metade dos
  -- dígitos iguais, e duas máquinas do mesmo cliente teriam códigos
  -- quase gêmeos.
  h = h ~ (h >> 16)
  h = (h * 0x85EBCA6B) & 0xFFFFFFFF
  h = h ~ (h >> 13)
  return h & 0xFFFFFFFF
end

--- Quatro dígitos hexadecimais a partir de um texto e de um tempero.
local function bloco(texto, tempero)
  return ('%04X'):format(mistura(texto .. '|' .. tempero) & 0xFFFF)
end

--- O que identifica esta máquina, antes de virar código.
--
--  Injetável para os testes: sem isto, a única forma de testar seria
--  mexer nas variáveis de ambiente do processo.
function Licenca.identidade(ambiente)
  local pegar = ambiente or os.getenv
  local partes = {}
  for _, nome in ipairs({ 'COMPUTERNAME', 'USERNAME', 'PROCESSOR_IDENTIFIER',
                          'HOSTNAME', 'USER' }) do
    local v = pegar(nome)
    if v and v ~= '' then partes[#partes + 1] = nome .. '=' .. v end
  end
  -- Máquina sem nenhuma dessas variáveis existe (um Linux enxuto), e
  -- devolver vazio faria todas elas compartilharem o mesmo código.
  if #partes == 0 then return nil end
  return table.concat(partes, ';')
end

--- O código que o cliente manda ao vendedor: LB-XXXX-XXXX.
--  @return string, ou nil se não deu para identificar a máquina
function Licenca.codigoDaMaquina(ambiente)
  local id = Licenca.identidade(ambiente)
  if not id then return nil end
  return ('LB-%s-%s'):format(bloco(id, 'a'), bloco(id, 'b'))
end

--- Só os dígitos, em maiúsculas: aceita o que o cliente digitou com
--  espaço a mais, minúscula ou sem os hífens.
local function limpar(texto)
  return (tostring(texto or ''):upper():gsub('[^0-9A-Z]', ''))
end

--- A chave que corresponde a um código de máquina.
--
--  É esta função que tools/gerar_chave.lua chama. Ela vive aqui, e não
--  no gerador, porque o programa precisa dela para conferir — as duas
--  pontas têm de usar exatamente a mesma conta.
function Licenca.chaveDe(codigo)
  local base = limpar(codigo)
  if base == '' then return nil end
  local sal = segredo()
  return ('%s-%s-%s-%s'):format(
    bloco(base, sal .. '1'), bloco(base, sal .. '2'),
    bloco(base, sal .. '3'), bloco(base, sal .. '4'))
end

--- A CHAVE MESTRA DO MÊS — para o desenvolvedor, não para venda.
--
--  Abre qualquer máquina, e é assim que se faz uma demonstração no
--  computador do cliente sem emitir chave para ele, ou se destrava uma
--  instalação para dar suporte.
--
--  VENCE NA VIRADA DO MÊS, e é isso que a torna aceitável. Uma mestra
--  eterna vazada uma vez está vazada para sempre — e vazar é o que
--  acontece com o que a gente digita na frente dos outros. Vencendo, o
--  estrago tem prazo, e emitir a do mês seguinte é um clique.
--
--  NÃO ESTÁ ESCRITA EM LUGAR NENHUM: é calculada do segredo com o ano e
--  o mês. Uma constante no código seria achada por quem procurasse
--  qualquer coisa parecida com uma senha.
--
--  @param quando  opcional, os.time() de referência (para testar)
function Licenca.chaveMestra(quando)
  local mes = os.date('%Y%m', quando)
  local sal = segredo() .. '#mestra#' .. mes
  return ('%s-%s-%s-%s'):format(
    bloco(mes, sal .. '1'), bloco(mes, sal .. '2'),
    bloco(mes, sal .. '3'), bloco(mes, sal .. '4'))
end

--- Que tipo de chave é esta? 'maquina', 'mestra' ou nil.
--
--  A janela usa isto para dizer na tela quando está aberta na mestra: o
--  pior desfecho desta funcionalidade seria uma máquina de cliente ficar
--  rodando na chave do desenvolvedor sem ninguém notar até ela vencer,
--  no meio de um show.
function Licenca.tipoDaChave(chave, ambiente, quando)
  local limpa = limpar(chave)
  if limpa == '' then return nil end

  local codigo = Licenca.codigoDaMaquina(ambiente)
  if codigo then
    local esperada = Licenca.chaveDe(codigo)
    if esperada and limpa == limpar(esperada) then return 'maquina' end
  end

  if limpa == limpar(Licenca.chaveMestra(quando)) then return 'mestra' end
  return nil
end

--- Esta chave vale nesta máquina?
function Licenca.confere(chave, ambiente, quando)
  return Licenca.tipoDaChave(chave, ambiente, quando) ~= nil
end

--- Devolve ao formato de origem o que o cliente colou de qualquer jeito.
--
--  Duas formas, e a diferença importa: o CÓDIGO da máquina é
--  `LB-XXXX-XXXX` — prefixo mais dois blocos —, e a CHAVE é
--  `XXXX-XXXX-XXXX-XXXX`, quatro blocos e nenhum prefixo. Cortar tudo de
--  quatro em quatro estragava o código, que voltava como `LB17-5ACA-D3`
--  e não casava com nada.
function Licenca.formatar(texto)
  local cru = limpar(texto)
  if cru:sub(1, 2) == 'LB' then
    local resto = cru:sub(3)
    local partes = { 'LB' }
    for i = 1, #resto, 4 do partes[#partes + 1] = resto:sub(i, i + 3) end
    return table.concat(partes, '-')
  end
  local partes = {}
  for i = 1, #cru, 4 do partes[#partes + 1] = cru:sub(i, i + 3) end
  return table.concat(partes, '-')
end

return Licenca
]=], "@core/licenca.lua"))(...)
end

-- ============================ core.atualizacao
package.preload["core.atualizacao"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / core/atualizacao.lua

  Procurar, baixar e instalar uma versão nova.

  O MANIFESTO é um arquivo de texto de três linhas, publicado por quem
  vende (ver Version.MANIFESTO):

      1.0.1
      https://.../LumiBridge_standalone.lua
      O que mudou, numa frase.

  COMO O DOWNLOAD ACONTECE
    Pelo `curl`, que o Windows 10 traz de fábrica desde 2018, chamado por
    os.execute. O ReaScript não tem cliente HTTP próprio, e depender de
    uma extensão a mais para atualizar seria uma dependência que só
    aparece na hora de resolver um problema.

  O CUIDADO QUE ESTE ARQUIVO EXISTE PARA TER
    Baixar por cima do programa que está rodando é a operação mais
    perigosa que ele faz. Um arquivo truncado — internet caindo no meio,
    servidor devolvendo uma página de erro — sobrescrito por cima do
    LumiBridge deixa o cliente sem programa nenhum, no dia do show.

    Por isso o download vai para um arquivo AO LADO, é conferido, e só
    então substitui. Confere três coisas: tamanho plausível, o Lua
    compila, e a versão de dentro é a que o manifesto prometeu. Qualquer
    uma falhando, o original não é tocado.

  TESTÁVEL NO TERMINAL. `baixar` e `ler` são injetáveis: os testes trocam
  a rede e o disco por funções de mentira e exercitam todos os desfechos
  — inclusive os ruins, que são os que importam aqui.
------------------------------------------------------------------------]]

local Atualizacao = {}

--- Quanto tempo esperar pela rede, em segundos. Curto de propósito:
--  quem clicou está olhando para a tela.
Atualizacao.ESPERA = 10

--- Menor tamanho aceitável para o programa baixado, em bytes.
--
--  O standalone passa de 700 KB. Uma página de erro do GitHub tem uns
--  poucos KB, e um download cortado, menos ainda. Cem mil é folgado o
--  bastante para não recusar um programa que emagreceu e apertado o
--  bastante para recusar qualquer coisa que não seja ele.
Atualizacao.MINIMO = 100000

--- Baixa uma URL para um arquivo. Trocável nos testes.
--  @return boolean
function Atualizacao.baixar(url, destino)
  if not url or url == '' or not destino then return false end
  -- -L segue redirecionamento (o GitHub usa), -f falha em erro HTTP em
  -- vez de gravar a página de erro, -s cala a barra de progresso.
  local comando = ('curl -L -f -s --max-time %d -o "%s" "%s"')
    :format(Atualizacao.ESPERA, destino, url)
  local ok = os.execute(comando)
  return ok == true or ok == 0
end

--- Lê um arquivo inteiro. Trocável nos testes.
function Atualizacao.ler(caminho)
  local f = io.open(caminho, 'rb')
  if not f then return nil end
  local conteudo = f:read('a')
  f:close()
  return conteudo
end

--- Escreve um arquivo inteiro. Trocável nos testes.
function Atualizacao.escrever(caminho, conteudo)
  local f = io.open(caminho, 'wb')
  if not f then return false end
  f:write(conteudo)
  f:close()
  return true
end

--- Interpreta o manifesto de três linhas.
--  @return { versao, url, notas } ou nil
function Atualizacao.lerManifesto(texto)
  if not texto then return nil end
  local linhas = {}
  for linha in tostring(texto):gmatch('[^\r\n]+') do
    linhas[#linhas + 1] = (linha:gsub('^%s+', ''):gsub('%s+$', ''))
  end
  local versao = linhas[1] and linhas[1]:match('^%d+%.%d+%.%d+$')
  if not versao then return nil end
  return { versao = versao, url = linhas[2] or '',
           notas = table.concat(linhas, ' ', 3) }
end

--- Há versão nova?
--
--  @param manifestoURL  de onde ler; vazio desliga a procura
--  @param instalada     versão de agora, "1.0.0"
--  @param temp          caminho de um arquivo temporário
--  @return nil quando não há nada novo, ou { versao, url, notas }
--  @return mensagem para a tela
function Atualizacao.procurar(manifestoURL, instalada, temp, Version)
  if not manifestoURL or manifestoURL == '' then
    return nil, 'a procura por atualizações não está configurada'
  end
  if not Atualizacao.baixar(manifestoURL, temp) then
    return nil, 'não consegui falar com o servidor'
  end

  local m = Atualizacao.lerManifesto(Atualizacao.ler(temp))
  if not m then return nil, 'o servidor respondeu algo que não entendi' end

  if not Version.maisNovaQue(m.versao, instalada) then
    return nil, ('você já está na versão mais nova (%s)'):format(instalada)
  end
  return m, ('versão %s disponível'):format(m.versao)
end

--- Baixa e instala, por cima do arquivo que está rodando.
--
--  @param url      de onde baixar o programa
--  @param destino  o arquivo a substituir
--  @param versao   a que o manifesto prometeu, para conferir
--  @return boolean, mensagem
--- A versão declarada dentro de um programa LumiBridge.
--
--  Lê os três números de core/version.lua — embutido no arquivo único —
--  e os remonta. Devolve nil quando não os encontra, e quem chama trata
--  isso como "não sei dizer", que é diferente de "está errado".
function Atualizacao.versaoDe(conteudo)
  if type(conteudo) ~= 'string' then return nil end
  local M = conteudo:match('Version%.MAIOR%s*=%s*(%d+)')
  local N = conteudo:match('Version%.MENOR%s*=%s*(%d+)')
  local C = conteudo:match('Version%.CORRECAO%s*=%s*(%d+)')
  if not (M and N and C) then return nil end
  return ('%s.%s.%s'):format(M, N, C)
end

function Atualizacao.instalar(url, destino, versao)
  if not url or url == '' then return false, 'sem endereço para baixar' end

  local novo = destino .. '.novo'
  if not Atualizacao.baixar(url, novo) then
    return false, 'não consegui baixar'
  end

  local conteudo = Atualizacao.ler(novo)
  if not conteudo or #conteudo < Atualizacao.MINIMO then
    return false, 'o download veio incompleto — nada foi alterado'
  end

  -- COMPILA? Um arquivo cortado ao meio é Lua inválido, e é a única
  -- forma barata de saber que o que chegou é um programa.
  local pedaco, erro = load(conteudo, 'atualizacao')
  if not pedaco then
    return false, 'o arquivo baixado não é válido (' .. tostring(erro)
                  .. ') — nada foi alterado'
  end

  -- E É A VERSÃO PROMETIDA? Protege do servidor com um arquivo velho no
  -- lugar: sem isto, "atualizar" poderia instalar a versão anterior.
  --
  -- ELE PROCURAVA A STRING "1.1.0" DENTRO DO ARQUIVO, e ela nunca esteve
  -- lá: o programa guarda a versão em três números separados
  -- (Version.MAIOR/MENOR/CORRECAO). A conferência portanto NUNCA passou,
  -- em versão nenhuma — a atualização automática existia, achava a
  -- versão nova, baixava, e recusava a instalação com a mensagem de um
  -- servidor adulterado. O defeito ficou escondido porque testar não
  -- atualiza, e porque a parte que ACHA a versão nova funcionava.
  --
  -- Agora os três números são lidos do arquivo baixado e remontados. É a
  -- mesma fonte que o programa usa para se dizer qual versão é.
  if versao then
    local achada = Atualizacao.versaoDe(conteudo)
    if not achada then
      return false, 'não consegui ler a versão do arquivo baixado '
                    .. '— nada foi alterado'
    end
    if achada ~= versao then
      return false, ('o arquivo baixado é a versão %s, e não a %s '
                     .. '— nada foi alterado'):format(achada, versao)
    end
  end

  -- GUARDA O ANTERIOR antes de trocar. Se a versão nova tiver um defeito
  -- no dia do show, voltar é renomear um arquivo.
  local anterior = Atualizacao.ler(destino)
  if anterior then Atualizacao.escrever(destino .. '.anterior', anterior) end

  if not Atualizacao.escrever(destino, conteudo) then
    return false, 'não consegui escrever no lugar do programa'
  end
  return true, 'atualizado — feche e abra o LumiBridge'
end

return Atualizacao
]=], "@core/atualizacao.lua"))(...)
end

-- ============================ midi.output
package.preload["midi.output"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / midi/output.lua

  Envio de MIDI para uma porta de saída de hardware do REAPER.

  ONDE ESTE MÓDULO SE ENCAIXA
    core/  é Lua puro e não conhece o REAPER.
    midi/  é a camada que fala com o REAPER para enviar MIDI.
    ui/    é a camada que fala com o REAPER para desenhar.

    Manter o MIDI separado da UI importa: se um dia a rota de envio
    mudar (porta virtual, track com JSFX, OSC), só este arquivo muda.
    A interface continua chamando MidiOut.send(comando) e pronto.

  COMO O ENVIO FUNCIONA
    reaper.StuffMIDIMessage(modo, byte1, byte2, byte3) injeta uma
    mensagem de 3 bytes. O modo escolhe o destino:

      0        teclado virtual
      1        MIDI-como-controle (mapa de ações)
      16 + N   dispositivo de saída de hardware número N

    Então enviar para a porta 2 significa modo 18. As portas são as
    mesmas que aparecem em Options > Preferences > MIDI Devices.

    A mensagem é enfileirada, não tem precisão de sample. Para disparo
    de cena de iluminação feito por mão humana isso é irrelevante — a
    latência de reação já é uma ordem de grandeza maior.

  TESTABILIDADE
    MidiOut.backend permite injetar um REAPER falso nos testes.
    Em produção fica nil e o módulo usa o reaper de verdade.
------------------------------------------------------------------------]]

local MidiOut = {}

--- Deslocamento de modo para dispositivos de saída de hardware.
local HARDWARE_MODE_BASE = 16

-- Modo "teclado virtual": a mensagem entra no REAPER como se viesse de
-- um teclado MIDI e percorre o caminho normal — track armada, com
-- monitoração ligada, saindo pela saída de hardware DELA.
--
-- É exatamente o percurso que funciona quando o REAPER toca o item
-- gravado. O modo de porta direta depende da thread de áudio esvaziar
-- uma fila, e é aí que as mensagens se perdem com o transporte parado.
local VIRTUAL_KEYBOARD_MODE = 0

--- Como as mensagens chegam ao Lumikit.
--    'porta'  -> direto na porta escolhida (StuffMIDIMessage 16+n)
--    'track'  -> pelo teclado virtual, saindo pela track (modo 0)
MidiOut.route = 'porta'

-- Estado do módulo.
MidiOut.backend     = nil    -- injetável nos testes
MidiOut.deviceIndex = nil    -- índice da porta escolhida
MidiOut.deviceName  = nil
MidiOut.enabled     = true

-- Contadores e último evento, para o painel da interface.
MidiOut.sentCount  = 0
MidiOut.lastMessage = nil
MidiOut.lastError   = nil

local function api()
  return MidiOut.backend or reaper
end

-- ------------------------------------------------------------ portas

--- Lista as portas de saída MIDI presentes no REAPER.
--  @return table  { { index = 0, name = 'loopMIDI Port' }, ... }
function MidiOut.listDevices()
  local r = api()
  local out = {}
  local count = r.GetNumMIDIOutputs and r.GetNumMIDIOutputs() or 0

  for i = 0, count - 1 do
    -- GetMIDIOutputName devolve (presente, nome). Portas configuradas
    -- mas ausentes aparecem na contagem e precisam ser filtradas.
    local present, name = r.GetMIDIOutputName(i, '')
    if present and name and name ~= '' then
      out[#out + 1] = { index = i, name = name }
    end
  end

  return out
end

--- Seleciona a porta pelo índice do REAPER.
function MidiOut.setDevice(index, name)
  MidiOut.deviceIndex = index
  MidiOut.deviceName  = name
  MidiOut.lastError   = nil
end

--- Procura uma porta pelo nome. Usado para restaurar a escolha anterior.
--  @return table|nil  a porta encontrada
function MidiOut.findDeviceByName(name)
  if not name or name == '' then return nil end
  for _, dev in ipairs(MidiOut.listDevices()) do
    if dev.name == name then return dev end
  end
  return nil
end

--- Uma porta está escolhida e o envio está ligado?
--- O motor de áudio do REAPER está rodando?
--
--  IMPORTANTE PARA O ENVIO MIDI.
--
--  StuffMIDIMessage não fala com a placa diretamente: enfileira a
--  mensagem para a thread de áudio entregar. Com o dispositivo fechado
--  essa thread não roda, a fila não é esvaziada e NADA chega ao Lumikit
--  — sem erro nenhum, porque do ponto de vista do script o envio
--  funcionou.
--
--  É por isso que tudo funciona com o play rodando e nada funciona
--  parado: o play reabre o dispositivo.
--
--  O REAPER fecha o dispositivo sozinho quando a preferência
--  "Close audio device when stopped and application is inactive"
--  está ligada (Options > Preferences > Audio).
function MidiOut.audioRunning()
  local r = api()
  if not r.Audio_IsRunning then return true end
  local ok, rodando = pcall(r.Audio_IsRunning)
  if not ok then return true end
  return rodando == true or rodando == 1
end

function MidiOut.isReady()
  if MidiOut.route == 'track' then return MidiOut.enabled end
  return MidiOut.enabled and MidiOut.deviceIndex ~= nil
end

-- ------------------------------------------------------------ envio

--- Envia três bytes crus para a porta escolhida.
--  @return boolean, string|nil
function MidiOut.sendRaw(status, data1, data2)
  if not MidiOut.enabled then
    return false, 'envio desligado'
  end
  -- No modo 'track' não há porta a escolher: quem define o destino é a
  -- saída de hardware da própria track.
  if MidiOut.route ~= 'track' and MidiOut.deviceIndex == nil then
    MidiOut.lastError = 'nenhuma porta MIDI selecionada'
    return false, MidiOut.lastError
  end

  -- Bytes precisam ser inteiros dentro da faixa MIDI.
  --
  -- LIMITAR, não mascarar. Mascarar embrulha o valor em silêncio: 300
  -- viraria 44 e o Lumikit receberia uma nota completamente diferente
  -- da pretendida, sem nenhum sinal de que algo deu errado.
  local function clamp(v, hi)
    v = math.floor(tonumber(v) or 0)
    if v < 0 then return 0 end
    if v > hi then return hi end
    return v
  end

  status = clamp(status, 0xFF)
  data1  = clamp(data1,  0x7F)
  data2  = clamp(data2,  0x7F)

  if MidiOut.route == 'track' then
    -- Pelo teclado virtual: a track armada recebe e reenvia pela saída
    -- de hardware configurada nela.
    api().StuffMIDIMessage(VIRTUAL_KEYBOARD_MODE, status, data1, data2)

    -- SOLTA A TECLA logo em seguida.
    --
    -- Neste caminho o REAPER trata a nota como uma tecla SEGURADA. Sem
    -- o Note Off, ela fica presa e o próximo acionamento da mesma nota
    -- é ignorado — o botão funciona na primeira vez e nunca mais.
    --
    -- O Lumikit não se importa: ele age no Note On e ignora o Note Off
    -- (usedata2="false" em todos os mapeamentos).
    if (status & 0xF0) == 0x90 then
      local canal = status & 0x0F
      api().StuffMIDIMessage(VIRTUAL_KEYBOARD_MODE, 0x80 | canal, data1, 0)
    end
  else
    api().StuffMIDIMessage(HARDWARE_MODE_BASE + MidiOut.deviceIndex,
                           status, data1, data2)
  end

  MidiOut.sentCount  = MidiOut.sentCount + 1
  MidiOut.lastError  = nil
  MidiOut.lastMessage = { status = status, data1 = data1, data2 = data2 }
  return true
end

--- Envia um comando do Modelo.
--  @param command  tabela vinda de Model.command()
--  @param override valor opcional para o terceiro byte (posição de fader)
function MidiOut.send(command, override)
  if not command then return false, 'comando vazio' end
  local data2 = override or command.data2
  return MidiOut.sendRaw(command.status, command.data1, data2)
end

--- Envia todos os comandos de um elemento do layout.
--  Um controle pode ter mais de um comando mapeado no .form.
--  @return integer quantidade enviada
function MidiOut.sendAll(commands, override)
  if not commands then return 0 end
  local n = 0
  for _, cmd in ipairs(commands) do
    if MidiOut.send(cmd, override) then n = n + 1 end
  end
  return n
end

--- Envia a SOLTURA de um comando de nota (para botões momentâneos).
--
--  Precisa ser um Note Off de verdade (status 0x80), não um Note On com
--  velocity 0. O .form marca usedata2="false" nesses mapeamentos, ou
--  seja, o Lumikit ignora a velocity ao casar a mensagem — um Note On
--  com velocity 0 seria lido como um novo acionamento, e a fumaça
--  ligaria de novo em vez de desligar.
function MidiOut.sendRelease(command)
  if not command then return false end
  if (command.status & 0xF0) ~= 0x90 then return false end
  local channel = command.status & 0x0F
  return MidiOut.sendRaw(0x80 | channel, command.data1, 0)
end

--- Solta todos os comandos de nota de um controle.
function MidiOut.releaseAll(commands)
  if not commands then return 0 end
  local n = 0
  for _, cmd in ipairs(commands) do
    if MidiOut.sendRelease(cmd) then n = n + 1 end
  end
  return n
end

--- Dispara uma nota de teste para conferir a rota até o Lumikit.
--  Nota 30 canal 1 é WAVE ALT no layout de referência.
function MidiOut.sendTestNote()
  return MidiOut.sendRaw(0x90, 30, 127)
end

--- Zera os contadores do painel.
function MidiOut.resetStats()
  MidiOut.sentCount   = 0
  MidiOut.lastMessage = nil
  MidiOut.lastError   = nil
end

return MidiOut
]=], "@midi/output.lua"))(...)
end

-- ============================ midi.cclanes
package.preload["midi.cclanes"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / midi/cclanes.lua

  Esconde/mostra a área INTEIRA das CC lanes no editor MIDI do REAPER, pra
  sobrar mais espaço pro piano roll (as notas).

  Por que existe:
    Não há função nativa da API do REAPER pra isso — só ações POR LANE
    individual (ex.: duplo clique na alça de uma lane esconde só ela).
    A forma usada por scripts da comunidade (ver "js_Select CC lanes to
    show in MIDI item under mouse", do ReaTeam/ReaScripts) é editar
    direto o state chunk do item MIDI: apagar as linhas VELLANE e
    escrever uma única, mínima ("VELLANE -1 0 0"), pra esconder tudo — um
    editor MIDI precisa de pelo menos uma lane, ou SetItemStateChunk
    recusa o chunk.

    Guarda o chunk ORIGINAL inteiro antes de esconder, e restaura ele
    byte a byte pra mostrar de novo — não tenta reconstruir as lanes
    entendendo cada campo (tipo, altura no editor, altura inline...), o
    que seria mais frágil e arriscaria perder alguma coisa da tela do
    usuário. É por isso que este módulo mexe com o item MIDI, e não com
    "lanes": ele só sabe apagar tudo e devolver exatamente o que tirou.
------------------------------------------------------------------------]]

local CCLanes = {}

-- Injetável nos testes — mesmo padrão de midi/transport.lua e
-- midi/output.lua: sem isto, testar exigiria um REAPER de verdade.
CCLanes.backend = nil
local function api() return CCLanes.backend or reaper end

-- true enquanto as lanes estiverem escondidas por este módulo.
--
-- É um estado GLOBAL, não por item: o botão da barra de ferramentas é um
-- só. Trocar de item no editor MIDI enquanto escondido não confunde o
-- REAPER (cada item guarda o próprio chunk salvo, por identidade — ver
-- savedChunks), mas o RÓTULO do botão passa a valer para o item que
-- estiver ativo no momento do clique seguinte.
CCLanes.hidden = false

-- item (userdata do REAPER) -> chunk original completo, guardado antes
-- de esconder. Por identidade do próprio item: chaves assim são um
-- padrão comum em ReaScript Lua.
local savedChunks = {}

--- Item MIDI da take ativa no editor MIDI aberto no momento, ou nil (e
--  uma mensagem) se não houver editor MIDI aberto.
local function activeItem()
  local a = api()
  if not a.MIDIEditor_GetActive then
    return nil, 'esta versão do REAPER não expõe o editor MIDI ao ReaScript'
  end
  local editor = a.MIDIEditor_GetActive()
  if not editor then return nil, 'nenhum editor MIDI aberto' end

  local take = a.MIDIEditor_GetTake(editor)
  if not take then return nil, 'o editor MIDI não tem uma take ativa' end

  local item = a.GetMediaItemTake_Item(take)
  if not item then return nil, 'não achei o item da take ativa' end

  return item
end

--- Esconde a área de CC lanes do item MIDI ativo no editor.
--  @return true, ou false + mensagem do que impediu
function CCLanes.hide()
  local item, erro = activeItem()
  if not item then return false, erro end

  local ok, chunk = api().GetItemStateChunk(item, '', false)
  if not ok or not chunk then
    return false, 'não consegui ler o estado do item'
  end

  local novo = chunk:gsub('\nVELLANE [^\n]+', '')
  local trocou
  novo, trocou = novo:gsub('(\nIGNTEMPO %d[^\n]*)', '%1\nVELLANE -1 0 0', 1)
  if trocou == 0 then
    -- Sem o ponto de ancoragem esperado: chunk de um formato que este
    -- módulo não reconhece. Melhor recusar do que aplicar um chunk sem
    -- lane nenhuma, que o REAPER pode rejeitar de qualquer forma.
    return false, 'não achei onde inserir a lane mínima neste item'
  end

  local aplicado = api().SetItemStateChunk(item, novo, false)
  if not aplicado then
    -- Nada foi salvo em savedChunks ainda: o item não mudou de verdade.
    return false, 'o REAPER recusou o novo estado do item'
  end

  -- Só grava o chunk original DEPOIS de confirmar que a troca colou —
  -- assim uma tentativa recusada não deixa um "salvo" órfão que a
  -- próxima chamada a CCLanes.show() aplicaria por engano.
  savedChunks[item] = chunk
  CCLanes.hidden = true
  return true
end

--- Restaura as CC lanes do item MIDI ativo no editor, como estavam antes
--  de CCLanes.hide().
function CCLanes.show()
  local item, erro = activeItem()
  if not item then return false, erro end

  local chunk = savedChunks[item]
  if not chunk then
    CCLanes.hidden = false
    return false, 'nada guardado pra restaurar neste item'
  end

  local aplicado = api().SetItemStateChunk(item, chunk, false)
  if not aplicado then
    return false, 'o REAPER recusou restaurar o item'
  end

  savedChunks[item] = nil
  CCLanes.hidden = false
  return true
end

--- Alterna entre esconder e mostrar.
function CCLanes.toggle()
  if CCLanes.hidden then return CCLanes.show() else return CCLanes.hide() end
end

return CCLanes
]=], "@midi/cclanes.lua"))(...)
end

-- ============================ midi.timeline
package.preload["midi.timeline"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / midi/timeline.lua

  Escreve na timeline do REAPER o que o core/recorder decidiu.

  ONDE ESTE MÓDULO SE ENCAIXA
    core/recorder.lua  decide O QUE escrever, em QN, sem tocar no REAPER.
    midi/timeline.lua  converte para PPQ e escreve de fato.

    A separação permite testar toda a lógica de gravação no terminal.
    Este arquivo é a única parte que exige o REAPER aberto.

  POR QUE QN E NÃO SEGUNDOS
    A gravação é musical. Trabalhando em semínimas, uma mudança de
    andamento no projeto não desalinha o que já foi gravado.

  ITENS MIDI
    Escrever exige um item MIDI sob a posição. Procuramos um que já
    exista na track escolhida; se não houver, criamos. Se a gravação
    passar do fim do item, ele é esticado.
------------------------------------------------------------------------]]

local Historico = require('core.historico')

local Timeline = {}

Timeline.backend = nil     -- injetável nos testes

-- Índice da nota de cada linha aberta, para poder esticá-la.
-- Chave: tag do controle.
--
-- Declarado AQUI, com o resto do estado do módulo: estava lá embaixo e
-- as funções acima o viam como global inexistente.
local liveNotes = {}

local function api()
  return Timeline.backend or reaper
end

-- Track escolhida.
--- Metade do intervalo médio entre quadros do script, em segundos.
--  Atualizado a cada quadro pela janela; 1/60 é um chute inicial.
Timeline.frameCompensation = 1 / 60

--- Teto da compensação de quadro, em segundos.
--
--  Meio quadro é a estimativa certa quando a interface roda solta. Se
--  ela engasga, o intervalo cresce e a compensação passaria a deslocar
--  a gravação em centenas de milissegundos — corrigindo um problema com
--  outro. Acima deste teto, o certo é destravar a interface, não
--  compensar.
Timeline.MAX_FRAME_COMPENSATION = 0.030

Timeline.trackIndex = nil
Timeline.trackName  = nil

-- Diagnóstico.
Timeline.notesWritten = 0
Timeline.ccWritten    = 0
Timeline.lastError    = nil

-- ------------------------------------------------------------- tracks

function Timeline.listTracks()
  local r = api()
  local out = {}
  local n = r.CountTracks(0)
  for i = 0, n - 1 do
    local track = r.GetTrack(0, i)
    if track then
      local _, name = r.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
      if not name or name == '' then name = ('Track %d'):format(i + 1) end
      out[#out + 1] = { index = i, name = name }
    end
  end
  return out
end

function Timeline.setTrack(index, name)
  -- SÓ INVALIDA SE A TRACK MUDOU DE VERDADE.
  --
  -- `recheckBindings` revalida a ligação a cada dois segundos e chama
  -- isto quase sempre com a MESMA track. Invalidando sempre, o índice
  -- inteiro era jogado fora de dois em dois segundos e o MIDI relido do
  -- zero logo depois — um soluço regular no meio do desenho, que é
  -- exatamente como uma pulada aparece.
  if Timeline.trackIndex ~= index or Timeline.trackName ~= name then
    Timeline.invalidateIndex()
  end
  Timeline.trackIndex = index
  Timeline.trackName  = name
  Timeline.lastError  = nil
end

function Timeline.findTrackByName(name)
  if not name or name == '' then return nil end
  for _, t in ipairs(Timeline.listTracks()) do
    if t.name == name then return t end
  end
  return nil
end

function Timeline.track()
  if Timeline.trackIndex == nil then return nil end
  return api().GetTrack(0, Timeline.trackIndex)
end

function Timeline.isReady()
  return Timeline.track() ~= nil
end

-- ------------------------------------------------------- tempo e grade

--- Estado do transporte e da grade.
--  @return table { playing, time, qn, gridQN }
--- Latência de saída do dispositivo de áudio, em segundos.
--
--  Você OUVE o áudio já atrasado pelo buffer da placa. Ao gravar MIDI de
--  um teclado, o REAPER desconta isso sozinho — é por isso que tocar
--  piano por cima da música não sai atrasado. Um script não recebe esse
--  desconto de graça, então fazemos aqui.
--
--  Com buffer de 512 a 48 kHz são ~11 ms; com 1024, ~21 ms. Somado ao
--  relógio de 30 fps, é a parcela do atraso que NÃO é culpa da reação
--  humana, e é a única que dá para eliminar por completo.
function Timeline.outputLatency()
  local r = api()
  if not r.GetOutputLatency then return 0 end
  local ok, latency = pcall(r.GetOutputLatency)
  if ok and type(latency) == 'number' and latency >= 0 and latency < 1 then
    return latency
  end
  return 0
end

function Timeline.context(offsetSeconds)
  local r = api()
  local playing = (r.GetPlayState() & 1) == 1

  local time
  if playing then
    -- GetPlayPosition2 devolve a posição REAL do áudio; GetPlayPosition
    -- devolve a do playhead desenhado na tela, que é suavizada para não
    -- tremer. A diferença é pequena, mas é atraso puro e de graça.
    if r.GetPlayPosition2 then
      time = r.GetPlayPosition2()
    else
      time = r.GetPlayPosition()
    end
    -- Desconta a latência de saída do áudio. Isto NÃO é o tempo de
    -- reação: é o atraso entre o REAPER produzir a amostra e ela sair
    -- pela caixa de som. O que você ouviu no instante do clique já era
    -- passado.
    time = time - Timeline.outputLatency()

    -- Desconta metade do intervalo entre quadros. O script roda a ~30
    -- fps, então o clique aconteceu em algum ponto do quadro anterior;
    -- na média, meio quadro atrás. Sem isso sobra um viés sistemático
    -- de uns 17 ms, sempre para o mesmo lado.
    time = time - Timeline.frameCompensation

    -- Compensa o atraso de reação: o clique aconteceu DEPOIS do evento,
    -- então voltamos no tempo a diferença medida na calibração.
    time = time - (offsetSeconds or 0)
  else
    time = r.GetCursorPosition()
  end
  if time < 0 then time = 0 end

  -- division vem em semínimas: 0.25 é uma grade de 1/16.
  -- Mesma armadilha da projectGrid(): o primeiro retorno não é a grade.
  local division = Timeline.projectGrid()

  return {
    playing = playing,
    time    = time,
    qn      = r.TimeMap2_timeToQN(0, time),
    gridQN  = division,
  }
end

--- Converte segundos em semínimas, no andamento do projeto.
--- Grade a usar na gravação, em semínimas. 0.125 = 1/32, 0.25 = 1/16.
--
--  O EDITOR MIDI tem grade PRÓPRIA, separada da grade do arranjo, e é a
--  do editor que aparece no Piano Roll. Usar a do arranjo produzia notas
--  do tamanho errado: com arranjo em 1/16 e editor em 1/32, o release de
--  "uma célula" ocupava dois quadradinhos na tela.
--
--  MIDI_GetGrid devolve a grade do editor para um take. Sem take (ou em
--  versão antiga do REAPER), caímos na grade do arranjo.
-- Última grade lida do editor MIDI. Serve de reserva quando não há take
-- para consultar: melhor manter o valor que já estava certo do que
-- silenciosamente cair na grade do arranjo, que costuma ser outra.
local lastEditorGrid = nil

-- Guarda a grade por um instante.
--
-- A leitura varre os itens da track até achar um take MIDI. Numa track
-- com centenas de itens isso é caro, e a função é chamada várias vezes
-- por quadro (uma por leitura de posição). Meio segundo de validade é
-- imperceptível para quem muda a grade e economiza milhares de
-- varreduras por minuto.
local gridCache = { valor = nil, ate = 0 }

function Timeline.projectGrid()
  local r = api()

  local agora = r.time_precise and r.time_precise() or 0
  if gridCache.valor and agora < gridCache.ate then
    return gridCache.valor
  end

  local function guardar(v)
    gridCache.valor = v
    gridCache.ate = agora + 0.5
    return v
  end

  -- Só os PRIMEIROS itens da track. Num repertório, a track de luz tem
  -- centenas de itens, e varrer todos duas vezes por segundo custa caro
  -- sem trazer informação nova: a grade do editor é a mesma em todos.
  local track = Timeline.track()
  if track and r.MIDI_GetGrid then
    local limite = math.min(r.CountTrackMediaItems(track), 8) - 1
    for i = 0, limite do
      local item = r.GetTrackMediaItem(track, i)
      local take = r.GetActiveTake(item)
      if take and r.TakeIsMIDI(take) then
        local ok, grid = pcall(r.MIDI_GetGrid, take)
        if ok and type(grid) == 'number' and grid > 0 then
          lastEditorGrid = grid
          return guardar(grid)
        end
      end
    end
  end

  if lastEditorGrid then return guardar(lastEditorGrid) end

  if not r.GetSetProjectGrid then return guardar(0.25) end
  -- GetSetProjectGrid devolve (retval, division, swingmode, swingamt).
  -- O primeiro valor NÃO é a grade — pegá-lo comparava um booleano com
  -- número e derrubava o script.
  local ok, _, division = pcall(r.GetSetProjectGrid, 0, false)
  if ok and type(division) == 'number' and division > 0 then
    return guardar(division)
  end
  return guardar(0.25)
end

function Timeline.timeToQN(seconds)
  return api().TimeMap2_timeToQN(0, seconds)
end

function Timeline.qnToTime(qn)
  return api().TimeMap2_QNToTime(0, qn)
end

-- ------------------------------------------------- preparo da track

--- Deixa a track pronta para receber o MIDI do teclado virtual.
--
--  São três ajustes que o usuário teria de fazer à mão toda vez:
--    armar a track,
--    escolher a entrada "Virtual MIDI Keyboard",
--    ligar a monitoração.
--
--  A quarta condição — a saída de hardware apontando para o Lumikit —
--  NÃO é mexida aqui: escolher para onde o MIDI vai é decisão do
--  usuário, e sobrescrever isso poderia desviar o show para a porta
--  errada. O que fazemos é DETECTAR e avisar.
--
--  @return boolean pronta?, string o que falta
function Timeline.armForVirtualKeyboard()
  local track = Timeline.track()
  if not track then return false, 'nenhuma track escolhida' end

  local r = api()
  if not r.SetMediaTrackInfo_Value then return false, 'API indisponível' end

  -- Armar para gravação.
  r.SetMediaTrackInfo_Value(track, 'I_RECARM', 1)

  -- Entrada: TODAS as entradas MIDI, todos os canais.
  --
  -- O formato é 4096 + (dispositivo * 32) + canal. O dispositivo 63
  -- significa "todas as entradas", e é o que inclui o teclado virtual.
  --
  -- Antes eu usava 4096 puro, que é o dispositivo ZERO — e num sistema
  -- onde ele não existe a track ficava com "MIDI (not connected)".
  -- Nada entrava, e o MIDI não saía pela track.
  r.SetMediaTrackInfo_Value(track, 'I_RECINPUT', 4096 + 63 * 32)

  -- Monitoração ligada: sem ela a track recebe mas não repassa.
  r.SetMediaTrackInfo_Value(track, 'I_RECMON', 1)

  -- A saída de hardware é do usuário. Só conferimos se existe.
  --
  -- É I_MIDIHWOUT, não um "send": a saída MIDI de hardware é uma
  -- propriedade da track. Consultar GetTrackNumSends dizia que não
  -- havia saída mesmo com ela configurada, porque são coisas
  -- diferentes.
  --
  -- O formato é (dispositivo << 5) | canal, e -1 quando desligada.
  local saida = -1
  if r.GetMediaTrackInfo_Value then
    saida = r.GetMediaTrackInfo_Value(track, 'I_MIDIHWOUT') or -1
  end

  if saida < 0 then
    return false,
      'a track não tem saída de hardware MIDI apontando para o Lumikit'
  end

  return true, nil, saida >> 5
end

--- Descreve a entrada de gravação da track, para conferência na tela.
function Timeline.describeInput()
  local track = Timeline.track()
  if not track then return 'sem track' end

  local r = api()
  if not r.GetMediaTrackInfo_Value then return '?' end

  local v = r.GetMediaTrackInfo_Value(track, 'I_RECINPUT') or -1
  if v < 0 then return 'nenhuma' end
  if v < 4096 then return ('áudio %d'):format(v) end

  local dev = (v - 4096) >> 5
  local canal = (v - 4096) & 31
  return ('MIDI %s, canal %s')
    :format(dev == 63 and 'todas as entradas' or ('dispositivo ' .. dev),
            canal == 0 and 'todos' or tostring(canal))
end

--- Aponta a saída de hardware MIDI da track para um dispositivo.
--
--  Separado do preparo automático de propósito: escolher PARA ONDE o
--  MIDI vai é a decisão mais consequente de todas — apontar para a
--  porta errada no meio de um show manda os comandos para o lugar
--  errado. Fica num botão explícito.
--
--  @param deviceIndex índice da porta de saída
--  @param canal 0 = todos os canais
--- Para onde a track manda o MIDI dela, se é que manda.
--
--  I_MIDIHWOUT guarda os dois números num inteiro: os cinco bits de
--  baixo são o canal (0 = todos) e os de cima o índice da porta.
--  Negativo quer dizer desligado.
--
--  IMPORTA PARA O ESPELHO. Quando a track já entrega na mesma porta que
--  o LumiBridge usa, cada nota da programação chega DUAS vezes ao
--  Lumikit — uma tocada pelo REAPER e outra mandada por nós. Os
--  controles do Lumikit são toggle: dois Note On no mesmo botão acendem
--  e apagam, e o botão fica como estava. Foi o relatado: tocando pelo
--  LumiBridge o botão não acende no Lumikit, e o mesmo arquivo tocado só
--  pelo REAPER acende.
--
--  @return índice da porta, ou nil se a track não manda para lugar nenhum
--  @return boolean a track está muda?
function Timeline.saidaDaTrack()
  local track = Timeline.track()
  if not track then return nil, false end

  local r = api()
  if not r.GetMediaTrackInfo_Value then return nil, false end

  local ok, valor = pcall(r.GetMediaTrackInfo_Value, track, 'I_MIDIHWOUT')
  local mudo = false
  local okM, m = pcall(r.GetMediaTrackInfo_Value, track, 'B_MUTE')
  if okM and m and m > 0.5 then mudo = true end

  if not ok or not valor or valor < 0 then return nil, mudo end
  return math.floor(valor) >> 5, mudo
end

function Timeline.setMidiHardwareOut(deviceIndex, canal)
  local track = Timeline.track()
  if not track then return false end

  local r = api()
  if not r.SetMediaTrackInfo_Value then return false end

  local valor = (deviceIndex << 5) | (canal or 0)
  r.SetMediaTrackInfo_Value(track, 'I_MIDIHWOUT', valor)
  return true
end

-- --------------------------------------------------------------- itens

--- Devolve o take MIDI que cobre o intervalo, criando ou esticando o item.
--- Limites do item de gravação para uma posição.
--
--  A REGIÃO manda. Um item por música, do tamanho da região — não um
--  item por trecho gravado.
--
--  Antes, cada vez que a gravação começava fora dos itens existentes um
--  item novo era criado. Parar e voltar em pontos diferentes da música
--  produzia uma fileira de itens picotados, quando o certo é um só.
--
--  Sem região sob a posição, o item cobre a música inteira: é melhor um
--  item grande e vazio do que vários pedaços.
local function recordingBounds(startTime, endTime)
  local r = api()

  if r.EnumProjectMarkers3 and r.CountProjectMarkers then
    local _, markers, regions = r.CountProjectMarkers(0)
    for i = 0, (markers or 0) + (regions or 0) - 1 do
      local ok, isRegion, pos, rgnEnd = r.EnumProjectMarkers3(0, i)
      if ok and ok ~= 0 and isRegion
         and startTime >= pos - 1e-9 and startTime < rgnEnd then
        return pos, rgnEnd
      end
    end
  end

  -- SEM REGIÃO: um item modesto em volta da gravação.
  --
  -- Nunca o projeto inteiro. Um projeto com várias músicas ganharia um
  -- único item cobrindo todas elas, e gravar a terceira música mexeria
  -- no mesmo item da primeira. Sem região não há como saber onde a
  -- música começa e termina, então o mínimo é o mais seguro.
  local pad = 8.0
  local from = math.max(0, startTime - pad)
  return from, endTime + pad
end

local function takeFor(track, startTime, endTime)
  local r = api()

  local boundStart, boundEnd = recordingBounds(startTime, endTime)

  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')

    -- Aproveita QUALQUER item que sobreponha a região de trabalho, não
    -- só o que estiver exatamente sob a posição. É isso que evita
    -- multiplicar itens ao gravar em pontos diferentes da mesma música.
    if pos < boundEnd + 1e-9 and pos + len > boundStart - 1e-9 then
      local take = r.GetActiveTake(item)
      if take and r.TakeIsMIDI(take) then
        -- Estende para cobrir a região inteira, para o próximo trecho
        -- gravado cair dentro deste mesmo item.
        local novoFim = math.max(pos + len, endTime, boundEnd)
        if novoFim > pos + len then
          r.SetMediaItemInfo_Value(item, 'D_LENGTH', novoFim - pos)
        end
        return take
      end
    end
  end

  -- Nenhum item: cria UM, cobrindo a região inteira.
  local item = r.CreateNewMIDIItemInProj(track, boundStart,
                                         math.max(boundEnd, endTime))
  if not item then return nil end

  -- DESLIGAR O LOOP é obrigatório. No REAPER, item MIDI novo nasce com
  -- "loop source" ligado: ao esticar o item para caber a gravação, o
  -- conteúdo se repete e as notas aparecem duplicadas ao longo do
  -- trecho esticado. Aqui o item é um recipiente de gravação, não um
  -- laço musical.
  r.SetMediaItemInfo_Value(item, 'B_LOOPSRC', 0)

  return r.GetActiveTake(item)
end

--- Garante UM item MIDI cobrindo exatamente a região informada.
--
--  Chamado ao preparar a música. Se já houver item sobrepondo a região,
--  ele é ajustado ao tamanho dela em vez de nascer outro — dois itens na
--  mesma música é o defeito que isto existe para evitar.
--
--  @return take, criouAgora
--- Nomeia o item no padrão do usuário: "NOME DA MÚSICA - LUMIKIT".
local function nomearItem(item, nomeRegiao)
  local r = api()
  if not r.GetSetMediaItemTakeInfo_String then return end
  local take = r.GetActiveTake(item)
  if not take then return end
  local nome = ('%s - LUMIKIT'):format((nomeRegiao or ''):upper())
  pcall(r.GetSetMediaItemTakeInfo_String, take, 'P_NAME', nome, true)
end

--- @param nomeRegiao usado para nomear o item
--- Duração máxima aceita para uma música, em segundos.
--  Uma "região" de meia hora quase sempre significa que a região errada
--  foi escolhida — e criar um item desse tamanho passaria por cima de
--  várias outras músicas.
Timeline.MAX_REGION = 20 * 60

function Timeline.prepareRegion(startTime, endTime, nomeRegiao)
  local track = Timeline.track()
  if not track then return nil, false end

  -- TRAVA DE SEGURANÇA. Limites absurdos não geram item nenhum.
  local duracao = endTime - startTime
  if duracao <= 0 then
    Timeline.lastError = 'região sem duração'
    return nil, false
  end
  if duracao > Timeline.MAX_REGION then
    Timeline.lastError =
      ('região de %.0f min é grande demais para uma música')
        :format(duracao / 60)
    return nil, false
  end
  Timeline.lastError = nil

  local r = api()

  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')

    -- Só reaproveita item que já está DENTRO da região, com folga de um
    -- segundo. Antes bastava sobrepor, então um item grande de outra
    -- parte do projeto era arrastado para cá e redimensionado.
    local dentro = pos > startTime - 1.0 and pos + len < endTime + 1.0
    if dentro and pos < endTime and pos + len > startTime then
      local take = r.GetActiveTake(item)
      if take and r.TakeIsMIDI(take) then
        -- O item cobre a região EXATAMENTE: nem um tique além.
        r.SetMediaItemInfo_Value(item, 'D_POSITION', startTime)
        r.SetMediaItemInfo_Value(item, 'D_LENGTH', endTime - startTime)
        r.SetMediaItemInfo_Value(item, 'B_LOOPSRC', 0)
        nomearItem(item, nomeRegiao)
        return take, false
      end
    end
  end

  local item = r.CreateNewMIDIItemInProj(track, startTime, endTime)
  if not item then return nil, false end
  r.SetMediaItemInfo_Value(item, 'B_LOOPSRC', 0)
  -- Reafirma os limites: CreateNewMIDIItemInProj pode arredondar para
  -- o compasso, e o item passaria do fim da região.
  r.SetMediaItemInfo_Value(item, 'D_POSITION', startTime)
  r.SetMediaItemInfo_Value(item, 'D_LENGTH', endTime - startTime)
  nomearItem(item, nomeRegiao)
  Timeline.invalidateIndex()
  return r.GetActiveTake(item), true
end

--- ADOTA as notas que atravessam `timeSeconds`, sem cortá-las.
--
--  É o "punch in". A nota em curso NÃO pode ser partida em duas: cada
--  Note On alterna o controle no Lumikit, então uma nota picotada vira
--  dois acionamentos e o botão acaba APAGANDO no meio da música.
--
--  Em vez de cortar, o gravador assume a nota que já existe e continua
--  esticando a mesma. Do ponto de vista do arquivo, nada muda até você
--  mexer em algo — e é exatamente esse o objetivo.
--
--  @return table { { pitch, channel, startQN, index }, ... }
function Timeline.adoptAt(timeSeconds)
  local adotadas = {}
  local track = Timeline.track()
  if not track then return adotadas end

  local r = api()
  if not r.MIDI_GetNote then return adotadas end

  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')

    if timeSeconds >= pos and timeSeconds < pos + len then
      local take = r.GetActiveTake(item)
      if take and r.TakeIsMIDI(take) then
        local ppq = r.MIDI_GetPPQPosFromProjTime(take, timeSeconds)
        local _, count = r.MIDI_CountEvts(take)
        for n = 0, (count or 0) - 1 do
          local ok, _, _, s0, e0, chan, pitch = r.MIDI_GetNote(take, n)
          if ok and s0 <= ppq and e0 > ppq then
            adotadas[#adotadas + 1] = {
              pitch   = pitch,
              channel = chan + 1,
              startQN = Timeline.timeToQN(
                          r.MIDI_GetProjTimeFromPPQPos
                          and r.MIDI_GetProjTimeFromPPQPos(take, s0)
                          or timeSeconds),
              index   = n,
            }
          end
        end
      end
    end
  end

  return adotadas
end

--- Registra uma nota já existente como "em crescimento".
--  A partir daqui, growLive estica ESTA nota em vez de criar outra.
function Timeline.claimLive(tag, index)
  liveNotes[tag] = index
end

--- Quantas notas já existem dentro de um intervalo de tempo.
--
--  É o que distingue os dois modos de gravação:
--    zero  -> música vazia: o REC faz a ABERTURA (release + estado
--             inicial), porque não há nada a preservar.
--    >zero -> música já programada: o REC apenas OUVE, e só o clique
--             escreve. Escrever a abertura aqui criaria notas do nada
--             por cima de um trabalho já feito.
function Timeline.countNotesIn(startTime, endTime)
  local track = Timeline.track()
  if not track then return 0 end

  local r = api()
  if not r.MIDI_GetNote or not r.MIDI_CountEvts then return 0 end

  local total = 0
  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')

    if pos < endTime and pos + len > startTime then
      local take = r.GetActiveTake(item)
      if take and r.TakeIsMIDI(take) then
        local p0 = r.MIDI_GetPPQPosFromProjTime(take, startTime)
        local p1 = r.MIDI_GetPPQPosFromProjTime(take, endTime)
        local _, count = r.MIDI_CountEvts(take)
        for n = 0, (count or 0) - 1 do
          local ok, _, _, s0 = r.MIDI_GetNote(take, n)
          if ok and s0 >= p0 - 1 and s0 < p1 then total = total + 1 end
        end
      end
    end
  end

  return total
end

-- ---------------------------------------------------------- caudas

-- Quando uma nota é encurtada por causa de uma regravação, o pedaço que
-- ficou para a frente NÃO desaparece: ele é guardado aqui e devolvido
-- quando a gravação termina.
--
-- É o que faz a programação antiga voltar a valer depois do stop. Sem
-- isso, trocar uma cor no meio e parar apagava todo o resto da música
-- daquele controle.
local tails = {}

local function rememberTail(pitch, channel, endPPQ, take)
  local key = ('%d_%d'):format(channel, pitch)
  local atual = tails[key]
  -- Guarda o fim MAIS DISTANTE: se a mesma nota for cortada duas vezes,
  -- a cauda verdadeira é a da primeira vez.
  if not atual or endPPQ > atual.endPPQ then
    tails[key] = { pitch = pitch, channel = channel,
                   endPPQ = endPPQ, take = take }
  end
end

function Timeline.clearTails()
  tails = {}
end

--- Devolve as caudas guardadas que ainda vão além de `fromQN`.
--  Cada uma vira uma nota nova, do ponto informado até o fim original.
--
--  DIZ O QUE DEVOLVEU, e não só quantas.
--
--  É por aqui que a programação anterior volta a valer depois do stop, e
--  é o primeiro suspeito de "gravei dez segundos e ele preencheu a
--  música inteira": uma cauda que ia até o fim volta indo até o fim. Sem
--  os números no registro não dá para separar isso da própria gravação
--  ter crescido demais — na tela as duas coisas são idênticas.
Timeline.ultimasCaudas = {}
function Timeline.restoreTails(fromQN)
  local track = Timeline.track()
  Timeline.ultimasCaudas = {}
  if not track then Timeline.clearTails() return 0 end

  local r = api()
  local devolvidas = 0

  for _, t in pairs(tails) do
    if t.take then
      local ok, p0 = pcall(r.MIDI_GetPPQPosFromProjQN, t.take, fromQN)
      if ok and p0 and t.endPPQ > p0 + 1 then
        local okQ, ateQN = pcall(r.MIDI_GetProjQNFromPPQPos, t.take, t.endPPQ)
        Timeline.ultimasCaudas[#Timeline.ultimasCaudas + 1] = {
          pitch = t.pitch, canal = (t.channel or 0) + 1,
          deQN = fromQN, ateQN = okQ and ateQN or nil,
        }
        -- A nota nasce no ponto do stop: como os controles são toggle,
        -- este Note On é justamente o que devolve o estado anterior.
        r.MIDI_InsertNote(t.take, false, false, p0, t.endPPQ,
                          t.channel, t.pitch, 127, true)
        devolvidas = devolvidas + 1
      end
      if r.MIDI_Sort then r.MIDI_Sort(t.take) end
    end
  end

  Timeline.clearTails()
  Timeline.invalidateIndex()
  return devolvidas
end

--- Corta em `timeSeconds` as notas das alturas informadas.
--
--  Chamado no instante do CLIQUE, não ao apertar REC. Quando você troca
--  a cor no meio da música, a nota da cor anterior termina exatamente
--  ali — e só ela e as rivais do grupo, nada mais.
--
--  @param pitches tabela altura -> true
--  @return integer quantas foram cortadas
function Timeline.truncatePitchesAt(timeSeconds, pitches, channel)
  local track = Timeline.track()
  if not track or not pitches then return 0 end

  local r = api()
  if not r.MIDI_GetNote or not r.MIDI_SetNote then return 0 end

  local cortadas = 0

  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')

    -- `>= pos`, e não `> pos`.
    --
    -- Com `>`, o instante EXATO em que o item começa ficava de fora e o
    -- item inteiro era pulado: nada era cortado. Na prática isso é
    -- "regravar bem do início não substitui, ignora" — o defeito
    -- relatado. Regravar a partir do primeiro instante da música é uma
    -- posição legítima como qualquer outra.
    --
    -- As três funções irmãs deste arquivo (soundingAt, adoptAt e a
    -- limpeza de CC) sempre usaram `>=`; esta era a única fora do
    -- padrão, e é por isso que só a substituição falhava ali.
    if timeSeconds >= pos and timeSeconds < pos + len then
      local take = r.GetActiveTake(item)
      if take and r.TakeIsMIDI(take) then
        local ppq = r.MIDI_GetPPQPosFromProjTime(take, timeSeconds)
        local _, count = r.MIDI_CountEvts(take)
        -- De trás para frente: apagar uma nota renumera as seguintes, e
        -- percorrer para a frente pularia a vizinha de cada apagada.
        for n = (count or 0) - 1, 0, -1 do
          local ok, _, _, s0, e0, ch, pitch = r.MIDI_GetNote(take, n)
          if ok and pitches[pitch] and (channel == nil or ch == channel)
             and e0 > ppq + 1 then
            if s0 < ppq - 1 then
              -- Nota que COMEÇOU ANTES: encurta até aqui.
              --
              -- GUARDA A CAUDA antes de cortar: o pedaço que ia além do
              -- ponto volta a valer quando a gravação parar. Sem isto, o
              -- resto da música daquele controle ficava vazio.
              rememberTail(pitch, ch, e0, take)
              r.MIDI_SetNote(take, n, nil, nil, s0, ppq, nil, nil, nil, true)
              cortadas = cortadas + 1

            elseif s0 <= ppq + 1 and r.MIDI_DeleteNote then
              -- Nota que COMEÇA AQUI MESMO: apaga, não encurta.
              --
              -- Encurtá-la até o próprio início a deixaria com
              -- comprimento zero — e é por isso que a guarda antiga
              -- (`s0 < ppq - 1`) a excluía. Só que excluir do corte
              -- significava deixá-la INTEIRA, e era metade do defeito
              -- "regravar do início não substitui": no primeiro instante
              -- da música a nota velha começa exatamente onde a nova
              -- entra, então ela nunca era tocada e continuava valendo.
              --
              -- A cauda é guardada do mesmo jeito, para o que vinha
              -- depois do stop voltar a valer.
              rememberTail(pitch, ch, e0, take)
              r.MIDI_DeleteNote(take, n)
              cortadas = cortadas + 1
            end
          end
        end
        if r.MIDI_Sort then r.MIDI_Sort(take) end
      end
    end
  end

  Timeline.invalidateIndex()
  return cortadas
end


-- ------------------------------------------------------------ regravação

--- Substituir o que já existe, em vez de empilhar por cima?
--
--  Ligado, regravar um trecho apaga as notas ANTERIORES daquela mesma
--  altura no intervalo regravado. Sem isso, gravar vermelho e depois
--  azul por cima deixaria os dois na timeline e o Lumikit receberia as
--  duas mensagens.
--
--  Apagamos só a MESMA altura: as outras notas do trecho continuam
--  intactas, porque você pode estar regravando apenas um controle.
Timeline.overwrite = true

--- Remove as notas de uma altura dentro de um intervalo de PPQ.
--  @return integer quantas foram removidas
--- @param pitches tabela altura -> true: quais alturas apagar
--- @param exceto opcional: { pitch, startPPQ } que NUNCA é tocada.
--   É a própria nota em crescimento: sem essa ressalva ela caía no ramo
--   de exclusão e era apagada e recriada a cada quadro, o que deixava
--   emendas visíveis no Piano Roll.
local function clearRange(take, pitches, channel, fromPPQ, toPPQ, exceto)
  local r = api()
  if not r.MIDI_CountEvts or not r.MIDI_GetNote or not r.MIDI_DeleteNote then
    return 0
  end

  local _, noteCount = r.MIDI_CountEvts(take)
  if not noteCount or noteCount == 0 then return 0 end

  -- NADA ANTES DO PONTO DE ESCRITA PODE SER TOCADO.
  --
  -- Uma nota que COMEÇA antes do trecho é apenas ENCURTADA até o início
  -- dele; só é apagada a que nasce dentro do trecho. Antes, qualquer
  -- sobreposição apagava a nota inteira: trocar uma cor no meio da
  -- música destruía todo o trecho anterior dela, que ficava sem nada.
  --
  -- De trás para a frente: apagar por índice renumera os seguintes, e
  -- percorrer para a frente pularia notas.
  local removed = 0
  for i = noteCount - 1, 0, -1 do
    local ok, _, _, startPPQ, endPPQ, chan, notePitch = r.MIDI_GetNote(take, i)
    local ehPropria = exceto and notePitch == exceto.pitch
                      and math.abs(startPPQ - exceto.startPPQ) < 2
    if ok and pitches[notePitch] and chan == channel and not ehPropria then
      if startPPQ < toPPQ and endPPQ > fromPPQ then
        if startPPQ < fromPPQ - 1 then
          -- Vem de trás: preserva o passado e corta no ponto.
          -- A cauda é guardada para voltar quando a gravação parar.
          if r.MIDI_SetNote then
            rememberTail(notePitch, chan, endPPQ, take)
            r.MIDI_SetNote(take, i, nil, nil, startPPQ, fromPPQ,
                           nil, nil, nil, true)
          end
        else
          -- Nasce dentro do trecho regravado: essa sim é substituída.
          -- Se ela ia além do trecho, a parte de fora também é cauda.
          if endPPQ > toPPQ + 1 then
            rememberTail(notePitch, chan, endPPQ, take)
          end
          r.MIDI_DeleteNote(take, i)
          removed = removed + 1
        end
      end
    end
  end

  Timeline.notesRemoved = (Timeline.notesRemoved or 0) + removed
  Timeline.invalidateIndex()
  return removed
end


-- ------------------------------------------------------- notas ao vivo

function Timeline.resetLive()
  liveNotes = {}
end

-- ------------------------------------------------------------- desfazer

-- Uma SESSÃO de gravação é um único ponto de desfazer.
--
-- Antes, cada escrita abria e fechava seu próprio bloco. Com a gravação
-- ao vivo isso vira dezenas de blocos por segundo, e o Ctrl+Z desfazia
-- um pedacinho de nota por vez — seriam centenas de Ctrl+Z para voltar
-- ao estado anterior à gravação.
--
-- Com a sessão aberta, tudo o que for escrito entre o REC e o stop entra
-- num bloco só, e um Ctrl+Z desfaz a gravação inteira.
local sessionOpen = false

-- Escopo do ponto de desfazer.
--
-- 4 = itens de mídia. Era -1, que significa "TUDO": estado das tracks,
-- configurações, projeto inteiro. Com -1, um Ctrl+Z depois de regravar
-- um trecho levava junto muito mais do que a gravação.
--
-- Com 4, o desfazer volta exatamente ao estado dos itens antes do REC.
local UNDO_ITEMS = 4

-- Forma da curva dos Control Change.
-- 0 square, 1 linear, 2 slow start/end, 3 fast start, 4 fast end, 5 bezier.
local CC_SHAPE_SLOW = 2

function Timeline.beginSession()
  if sessionOpen then return end
  local r = api()

  -- GRAVAR APAGA O HISTÓRICO DO EDITOR.
  --
  -- As fotos guardadas descrevem o take como ele era ANTES desta
  -- gravação. Restaurar uma delas depois do stop escreveria aquele
  -- estado por cima — apagando tudo o que acabou de ser gravado. É
  -- exatamente o desastre que o histórico existe para impedir, e seria
  -- irônico introduzi-lo aqui.
  Timeline.esquecerEdicoes()

  if r.Undo_BeginBlock then r.Undo_BeginBlock() end
  sessionOpen = true
end

function Timeline.endSession(label)
  if not sessionOpen then return end
  local r = api()
  if r.Undo_EndBlock then
    r.Undo_EndBlock(label or 'LumiBridge: gravação', UNDO_ITEMS)
  end
  sessionOpen = false
end

function Timeline.inSession()
  return sessionOpen
end

--- Roda uma edição dentro de um ponto de desfazer PRÓPRIO.
--
--  POR QUE NÃO BASTAVA beginSession/endSession. Aquele par existe para a
--  GRAVAÇÃO: ele é ignorado se já houver sessão aberta, para o Ctrl+Z
--  desfazer a gravação inteira de uma vez. As edições manuais das faixas
--  usavam o mesmo par e herdavam esse comportamento — se qualquer coisa
--  tivesse deixado uma sessão aberta, cada edição virava parte de um
--  bloco alheio, e o desfazer não trazia a nota de volta.
--
--  Aqui é o contrário: cada edição é um passo de desfazer SEU. É o que se
--  espera de um editor — arrastei uma borda, Ctrl+Z devolve aquela borda,
--  não a gravação inteira.
--
--  MarkProjectDirty junto: o REAPER só grava um ponto de desfazer se
--  concluir que algo mudou, e para mudanças feitas pela API dentro de um
--  take essa conclusão nem sempre vem sozinha. Marcar é barato e tira a
--  dúvida.
--
--  @param label  o que aparece no menu Desfazer
--  @param fn     a edição
--  @return o que `fn` devolver
-- ------------------------------------------- desfazer PRÓPRIO do editor

--- Fotografa o MIDI de todos os itens da track escolhida.
--
--  UMA FOTO É O CONTEÚDO INTEIRO DOS TAKES, e não uma descrição do que
--  a edição fez. Foi escolha deliberada: descrever a operação exige uma
--  inversa escrita à mão para cada gesto — apagar nota, mover ponto,
--  juntar trechos, apagar quinze pontos de uma vez —, e a primeira que
--  saísse errada corromperia a timeline em silêncio. O conteúdo bruto
--  não tem esse risco: restaurar é escrever de volta o que estava lá.
--
--  MIDI_GetAllEvts devolve o buffer cru do take. É um memcpy, não uma
--  varredura evento a evento — dá para chamar a cada edição sem que
--  ninguém sinta.
--
--  @return tabela de { take, evts }, ou nil se esta instalação não tiver
--          a função (aí o editor volta a depender só do REAPER)
function Timeline.fotografar()
  local r = api()
  local track = Timeline.track()
  -- AS DUAS PONTAS. Fotografar sem como escrever de volta é trabalho
  -- jogado fora: o passo entraria no histórico e o desfazer não teria o
  -- que fazer com ele.
  if not track or not r.MIDI_GetAllEvts or not r.MIDI_SetAllEvts
     or not r.CountTrackMediaItems then
    return nil
  end

  local foto = {}
  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local take = item and r.GetActiveTake(item)
    if take and r.TakeIsMIDI(take) then
      local ok, buf = r.MIDI_GetAllEvts(take, '')
      if ok and buf then foto[#foto + 1] = { take = take, evts = buf } end
    end
  end
  return foto
end

--- O que mudou entre duas fotos.
--
--  Guardar a track inteira a cada passo seria desperdício: uma edição
--  mexe num item, e os outros da track são cópias idênticas do passo
--  anterior. Só os takes que mudaram entram no histórico.
--
--  @return recorte do ANTES e recorte do DEPOIS, ou nil se nada mudou
local function recortarMudanca(antes, depois)
  if not antes or not depois then return nil end

  local porTake = {}
  for _, a in ipairs(antes) do porTake[a.take] = a.evts end

  local a2, d2 = {}, {}
  for _, d in ipairs(depois) do
    local velho = porTake[d.take]
    if velho ~= nil and velho ~= d.evts then
      a2[#a2 + 1] = { take = d.take, evts = velho }
      d2[#d2 + 1] = { take = d.take, evts = d.evts }
    end
  end

  if #d2 == 0 then return nil end
  return a2, d2
end

--- Escreve uma foto de volta nos takes.
--
--  @return boolean deu para aplicar tudo?
function Timeline.restaurarFoto(foto)
  local r = api()
  if not foto or not r.MIDI_SetAllEvts then return false end

  for _, f in ipairs(foto) do
    -- O TAKE AINDA EXISTE? Um item apagado por fora deixa o ponteiro
    -- inválido, e escrever nele derruba o REAPER inteiro — não é um
    -- erro de Lua que dê para apanhar com pcall.
    if r.ValidatePtr2 and not r.ValidatePtr2(0, f.take, 'MediaItem_Take*') then
      return false
    end
  end

  for _, f in ipairs(foto) do
    r.MIDI_SetAllEvts(f.take, f.evts)
    if r.MIDI_Sort then r.MIDI_Sort(f.take) end
  end

  if r.MarkProjectDirty then pcall(r.MarkProjectDirty, 0) end
  Timeline.invalidateIndex()
  return true
end

local historico = Historico.novo(function(foto)
  return Timeline.restaurarFoto(foto)
end)

function Timeline.podeDesfazerEdicao() return Historico.podeDesfazer(historico) end
function Timeline.podeRefazerEdicao()  return Historico.podeRefazer(historico) end
function Timeline.rotuloDesfazerEdicao() return Historico.rotuloDesfazer(historico) end
function Timeline.rotuloRefazerEdicao()  return Historico.rotuloRefazer(historico) end
function Timeline.desfazerEdicao() return Historico.desfazer(historico) end
function Timeline.refazerEdicao()  return Historico.refazer(historico) end
function Timeline.esquecerEdicoes() Historico.limpar(historico) end
function Timeline.tamanhoDoHistorico() return Historico.tamanho(historico) end

--- Roda uma edição do editor como UM passo de desfazer NOSSO.
--
--  NÃO ABRE BLOCO NO REAPER, e é de propósito.
--
--  Abria antes, e era o bug: o REAPER descarta em silêncio um bloco que
--  ele julgue sem mudança, e aí o Ctrl+Z seguinte acertava o ponto
--  anterior — a gravação inteira. Foram três tentativas de fazê-lo
--  registrar; nenhuma pegou sempre.
--
--  Mantê-lo AGORA seria pior do que inútil. Com histórico próprio, os
--  dois desfazeres andariam em paralelo sobre o mesmo projeto: desfazer
--  três edições pela nossa pilha e depois cair na do REAPER faria o
--  REAPER restaurar o estado "antes da terceira edição" — que é DEPOIS
--  da primeira e da segunda. As duas voltariam do nada.
--
--  Com um dono só, a conta fecha: as edições são nossas, a gravação é do
--  REAPER, e a passagem de uma pilha para a outra acontece exatamente
--  onde o usuário espera.
--
--  @param label  o que aparece na dica do botão desfazer
--  @param fn     a edição
--  @return o que `fn` devolver
function Timeline.editar(label, fn)
  local r = api()

  -- Gravando, o bloco da gravação manda: fragmentá-lo faria o Ctrl+Z
  -- desfazer a gravação em pedacinhos.
  if sessionOpen then return fn() end

  -- SEM COMO FOTOGRAFAR, volta a ser edição do REAPER.
  --
  -- MIDI_GetAllEvts existe em toda instalação que este programa
  -- encontra, mas "toda" é uma aposta e o preço de errar é o desfazer
  -- sumir por completo nessa máquina. Caindo aqui, a edição vai para a
  -- pilha do REAPER como antes: às vezes ela registra, e às vezes é
  -- melhor do que nunca.
  local antes = Timeline.fotografar()
  if not antes then return Timeline.editarItens(label, fn) end

  local ok, resultado = pcall(fn)
  if r.MarkProjectDirty then pcall(r.MarkProjectDirty, 0) end

  local a2, d2 = recortarMudanca(antes, Timeline.fotografar())
  Timeline.ultimaEdicaoGuardada = a2 ~= nil
  if a2 then
    Historico.registrar(historico, label or 'LumiBridge: editar', a2, d2)
  end

  -- Um erro dentro da edição não pode escapar em silêncio: quem chamou
  -- precisa saber que a timeline não está no estado que ele pediu.
  if not ok then error(resultado, 0) end
  return resultado
end

--- Roda uma mudança que MEXE NOS ITENS, num ponto de desfazer do REAPER.
--
--  Criar o item da música e apagar a programação inteira não cabem na
--  foto: ela guarda o conteúdo dos takes que existem, e um take que
--  ainda não existe não tem o que fotografar. Estas duas continuam onde
--  sempre estiveram, na pilha do REAPER — e limpam a nossa, porque
--  qualquer foto tirada antes delas descreve um projeto que já não é
--  este.
function Timeline.editarItens(label, fn)
  local r = api()
  if sessionOpen then return fn() end

  if r.Undo_BeginBlock then r.Undo_BeginBlock() end
  local ok, resultado = pcall(fn)
  if r.MarkProjectDirty then pcall(r.MarkProjectDirty, 0) end
  if r.Undo_EndBlock then
    r.Undo_EndBlock(label or 'LumiBridge: editar', UNDO_ITEMS)
  end

  Historico.limpar(historico)

  if not ok then error(resultado, 0) end
  return resultado
end

--- Localiza uma nota pelo par altura + início, em ticks.
--
--  O índice é guardado em cache, mas VALIDADO antes de cada uso: apagar
--  ou inserir notas renumera as seguintes, e um índice velho apontaria
--  para a nota errada — que seria esticada no lugar da certa.
local function findNote(take, pitch, channel, startPPQ, hint)
  local r = api()
  if not r.MIDI_GetNote then return nil end

  if hint then
    local ok, _, _, s0, _, ch, p = r.MIDI_GetNote(take, hint)
    if ok and p == pitch and ch == channel and math.abs(s0 - startPPQ) < 2 then
      return hint
    end
  end

  local _, count = r.MIDI_CountEvts(take)
  for i = 0, (count or 0) - 1 do
    local ok, _, _, s0, _, ch, p = r.MIDI_GetNote(take, i)
    if ok and p == pitch and ch == channel and math.abs(s0 - startPPQ) < 2 then
      return i
    end
  end
  return nil
end

-- ------------------------------------------------------ punch-in


--- Início do próximo evento depois de uma posição, entre as alturas dadas.
--
--  É o LIMITE de crescimento de uma nota em gravação. Sem ele, regravar
--  uma cor no meio apagaria todas as trocas de cor até o fim da música,
--  porque a nota cresceria por cima delas. Com ele, a mudança vale só
--  até o próximo evento já programado — que sobrevive.
--
--  @return número em semínimas, ou nil se não houver evento adiante
function Timeline.nextEventQN(afterQN, pitches)
  local track = Timeline.track()
  if not track or not pitches then return nil end

  local r = api()
  if not r.MIDI_GetNote then return nil end

  local melhor = nil
  local afterTime = Timeline.qnToTime(afterQN)

  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local take = r.GetActiveTake(item)
    if take and r.TakeIsMIDI(take) then
      local ppqAfter = r.MIDI_GetPPQPosFromProjTime(take, afterTime)
      local _, count = r.MIDI_CountEvts(take)
      for n = 0, (count or 0) - 1 do
        local ok, _, _, s0, _, _, pitch = r.MIDI_GetNote(take, n)
        -- Uma tolerância de um tique evita que a própria nota recém
        -- criada seja tomada como o "próximo evento" dela mesma.
        if ok and pitches[pitch] and s0 > ppqAfter + 1 then
          local qn = r.MIDI_GetProjQNFromPPQPos
            and r.MIDI_GetProjQNFromPPQPos(take, s0) or nil
          if qn and (not melhor or qn < melhor) then melhor = qn end
        end
      end
    end
  end

  return melhor
end

-- ------------------------------------------------------ punch-in de CC

--- Apaga os pontos de CC de um fader ENTRE duas posições (bordas
--  preservadas).
--
--  Chamado ao regravar um trecho de fader: os pontos que já existiam
--  entre onde você pegou o fader e onde soltou perdem para a automação
--  nova — mesmo espírito do punch-in de nota (M5.3: nada antes do
--  clique é alterado), só que aqui não existe "cauda": o que vem DEPOIS
--  do fim do gesto não é tocado, e continua valendo como estava.
--
--  As DUAS BORDAS (startQN e endQN) são preservadas de propósito, não
--  apagadas: são exatamente as posições onde o chamador vai escrever
--  os pontos novos, e o dedup de posição exata do próprio Timeline.write
--  (M7.3) já cuida delas ali. Isso importa quando o mesmo fader é
--  regravado em vários gestos seguidos na MESMA gravação (ver
--  manualCursor em ui/window.lua): a borda de saída de um gesto é a
--  borda de entrada do próximo, e ela precisa sobreviver — é o ponto
--  que segura o valor entre os dois toques.
--
--  @param cc      número do Control Change
--  @param channel canal MIDI, 1-based (como vem do .form)
--  @param startQN início do trecho, em semínimas
--  @param endQN   fim do trecho, em semínimas
--  @return integer quantos pontos foram apagados
function Timeline.clearCCRange(cc, channel, startQN, endQN)
  local track = Timeline.track()
  if not track or not cc then return 0 end

  local r = api()
  if not r.MIDI_CountEvts or not r.MIDI_GetCC or not r.MIDI_DeleteCC then
    return 0
  end

  if endQN < startQN then startQN, endQN = endQN, startQN end

  -- Mesma conversão QN -> PPQ usada por Timeline.write para os pontos
  -- de CC (MIDI_GetPPQPosFromProjQN, direto). Ir por tempo (segundos)
  -- e voltar, como o resto deste arquivo faz para checar sobreposição
  -- de item, arredondaria diferente e poderia deslocar a borda por um
  -- tique — o suficiente para apagar por engano o ponto que deveria
  -- sobreviver.
  local startTime = Timeline.qnToTime(startQN)
  local endTime   = Timeline.qnToTime(endQN)
  local canal     = (channel or 1) - 1
  local apagados  = 0

  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')

    if pos <= endTime and pos + len >= startTime then
      local take = r.GetActiveTake(item)
      if take and r.TakeIsMIDI(take) then
        local p0 = r.MIDI_GetPPQPosFromProjQN(take, startQN)
        local p1 = r.MIDI_GetPPQPosFromProjQN(take, endQN)
        local _, _, ccCount = r.MIDI_CountEvts(take)
        for n = (ccCount or 0) - 1, 0, -1 do
          local ok, _, _, ccPPQ, _, ch, msg2 = r.MIDI_GetCC(take, n)
          if ok and msg2 == cc and ch == canal
             and ccPPQ > p0 and ccPPQ < p1 then
            r.MIDI_DeleteCC(take, n)
            apagados = apagados + 1
          end
        end
      end
    end
  end

  Timeline.invalidateIndex()
  return apagados
end

-- ------------------------------------------------------------ escrita

--- Escreve uma lista de intenções vindas do core/recorder.
--  @return integer quantidade escrita
function Timeline.write(intents)
  if not intents or #intents == 0 then return 0 end

  local track = Timeline.track()
  if not track then
    Timeline.lastError = 'nenhuma track selecionada'
    return 0
  end

  local r = api()
  -- Dentro de uma sessão de gravação, o bloco de desfazer já está aberto
  -- e cobre tudo. Abrir outro aqui fragmentaria o Ctrl+Z.
  local ownBlock = not sessionOpen
  if ownBlock and r.Undo_BeginBlock then r.Undo_BeginBlock() end

  local touched, written = {}, 0

  for _, it in ipairs(intents) do
    if it.kind == 'update' then
      -- Estica (ou finaliza) uma nota que já existe na timeline. É o que
      -- faz a nota crescer durante a execução, como numa gravação de
      -- áudio, em vez de aparecer só quando o botão é desligado.
      --
      -- O take precisa ser obtido AQUI. Ele é local a cada ramo do laço,
      -- e usá-lo antes disso pegava um `take` inexistente — a API do
      -- REAPER recusa e derruba o script.
      local t0 = Timeline.qnToTime(it.startQN)
      local t1 = Timeline.qnToTime(it.endQN)
      local take = takeFor(track, t0, t1)
      if take then
      local p0 = r.MIDI_GetPPQPosFromProjQN(take, it.startQN)
      local p1 = r.MIDI_GetPPQPosFromProjQN(take, it.endQN)
      if p1 <= p0 then p1 = p0 + 1 end
      local chan = (it.channel or 1) - 1

      -- Ao crescer por cima de notas já gravadas, elas são substituídas.
      -- Sem isto, a nota nova passava por cima das antigas e as duas
      -- ficavam soando ao mesmo tempo.
      --
      -- A limpeza começa DEPOIS do início da própria nota, para não
      -- apagar a si mesma nem mexer no que veio antes.
      if Timeline.overwrite and it.rivals ~= false then
        local alvos = { [it.pitch] = true }
        for p in pairs(it.rivals or {}) do alvos[p] = true end
        clearRange(take, alvos, chan, p0, p1,
                   { pitch = it.pitch, startPPQ = p0 })
      end

      local idx = findNote(take, it.pitch, chan, p0, liveNotes[it.live])
      if idx and r.MIDI_SetNote then
        liveNotes[it.live] = idx
        r.MIDI_SetNote(take, idx, nil, nil, p0, p1, nil, nil, nil, true)
        written = written + 1
      else
        -- A nota sumiu (apagada à mão, ou por uma rival): recria, para
        -- não perder o trecho já tocado.
        r.MIDI_InsertNote(take, false, false, p0, p1, chan,
                          it.pitch, it.velocity or 127, true)
        written = written + 1
      end

      if it.final then liveNotes[it.live] = nil end
      end

    elseif it.kind == 'note' then
      local t0 = Timeline.qnToTime(it.startQN)
      local t1 = Timeline.qnToTime(it.endQN)
      local take = takeFor(track, t0, t1)
      if take then
        local p0 = r.MIDI_GetPPQPosFromProjQN(take, it.startQN)
        local p1 = r.MIDI_GetPPQPosFromProjQN(take, it.endQN)
        if p1 <= p0 then p1 = p0 + 1 end
        -- O canal do modelo é 1..16; a API do REAPER usa 0..15.
        local chan = (it.channel or 1) - 1

        -- Regravar um trecho substitui o que estava lá, em vez de
        -- empilhar. Sem isto, gravar vermelho e depois azul por cima
        -- deixaria os dois e o Lumikit receberia as duas mensagens.
        if Timeline.overwrite then
          -- Apaga a mesma altura E as rivais do mesmo grupo exclusivo.
          --
          -- Só a mesma altura não basta: regravar branco por cima de
          -- verde deixaria o verde no trecho, e o Lumikit receberia as
          -- duas cores. Num grupo "apenas um ativo", duas notas
          -- simultâneas é um estado impossível na tela real.
          local alvos = { [it.pitch] = true }
          if it.rivals then
            for p in pairs(it.rivals) do alvos[p] = true end
          end
          clearRange(take, alvos, chan, p0, p1)
        end

        r.MIDI_InsertNote(take, false, false, p0, p1,
                          chan, it.pitch, it.velocity, true)

        -- Guarda o índice para poder esticar esta nota nos próximos
        -- quadros, enquanto o botão continuar aceso.
        if it.live then
          liveNotes[it.live] = findNote(take, it.pitch, chan, p0, nil)
        end
        touched[take] = true
        written = written + 1
        Timeline.notesWritten = Timeline.notesWritten + 1
      end

    elseif it.kind == 'cc' then
      local t = Timeline.qnToTime(it.qn)
      local take = takeFor(track, t, t)
      if take then
        local p = r.MIDI_GetPPQPosFromProjQN(take, it.qn)

        -- APAGA o ponto que já existir aqui, antes de escrever.
        --
        -- MIDI_InsertCC não substitui: acrescenta. Sem esta limpeza, o
        -- ponto do preparo (no valor inicial) convivia com o ponto do
        -- movimento, e a automação subia de volta sozinha até o fim da
        -- música — o valor antigo continuava lá, disputando.
        if r.MIDI_CountEvts and r.MIDI_GetCC and r.MIDI_DeleteCC then
          local canal = (it.channel or 1) - 1
          local _, _, ccCount = r.MIDI_CountEvts(take)
          for n = (ccCount or 0) - 1, 0, -1 do
            local ok, _, _, ccPPQ, _, ch, msg2 = r.MIDI_GetCC(take, n)
            if ok and msg2 == it.cc and ch == canal
               and math.abs(ccPPQ - p) < 4 then
              r.MIDI_DeleteCC(take, n)
            end
          end
        end

        r.MIDI_InsertCC(take, false, false, p, 0xB0,
                        (it.channel or 1) - 1, it.cc, it.value)

        -- Curva SLOW START/END, que é a usada no fluxo do usuário.
        --
        -- O REAPER guarda a forma da curva por evento; sem definir, o
        -- ponto nasce linear e o movimento fica seco.
        if r.MIDI_SetCCShape and r.MIDI_CountEvts and r.MIDI_GetCC then
          local _, _, ccCount = r.MIDI_CountEvts(take)
          for n = (ccCount or 0) - 1, 0, -1 do
            local ok, _, _, ccPPQ = r.MIDI_GetCC(take, n)
            if ok and math.abs(ccPPQ - p) < 2 then
              pcall(r.MIDI_SetCCShape, take, n, CC_SHAPE_SLOW, 0, true)
              break
            end
          end
        end
        touched[take] = true
        written = written + 1
        Timeline.ccWritten = Timeline.ccWritten + 1
      end
    end
  end

  -- Inserimos com noSort para não reordenar a cada nota; ordenamos no fim.
  for take in pairs(touched) do r.MIDI_Sort(take) end

  if ownBlock and r.Undo_EndBlock then
    r.Undo_EndBlock('LumiBridge: gravar na timeline', UNDO_ITEMS)
  end
  if written > 0 then Timeline.lastError = nil end
  Timeline.invalidateIndex()
  return written
end

-- ------------------------------------------------- índice de eventos

-- O ESPELHO NÃO PODE RELER O ITEM A CADA CONSULTA.
--
-- Ele pergunta dez vezes por segundo o que está soando, e cada pergunta
-- percorria todas as notas e todos os CC do item. Num item de música
-- inteira são centenas de eventos, e isso derrubava a taxa de quadros
-- justamente durante a reprodução — que é quando a interface precisa
-- responder.
--
-- Agora o item é lido UMA vez e vira um índice. As consultas seguintes
-- só olham a tabela. O índice é refeito quando a gravação escreve algo
-- ou quando a track muda.
--
-- ISSO ESTEVE ESCRITO AQUI SEM SER VERDADE. Só a troca de track
-- invalidava; nenhuma escrita invalidava. O índice sobrevivia intacto a
-- gravações inteiras, e o espelho continuava mostrando o que havia ANTES
-- delas — acender o que está gravado é a única função dele.
--
-- Passou despercebido porque soundingAt tem um caminho de reserva para
-- quando o índice está vazio, e ele varre o item de verdade. Num projeto
-- que começa vazio o índice nasce vazio, a reserva assume, e tudo
-- funciona — devagar, mas certo. O erro só aparece em projeto que JÁ tem
-- programação: aí o índice nasce cheio, a reserva nunca entra, e nada do
-- que se grava depois aparece.
--
-- Toda função que mexe em nota ou CC chama Timeline.invalidateIndex()
-- antes de devolver. É a lista inteira de quem escreve: prepareRegion,
-- restoreTails, truncatePitchesAt, clearRange, clearCCRange e write.
--
-- GRAVANDO, portanto, o índice é refeito o tempo todo: as notas crescem
-- a cada quadro, e crescer é escrever. Isso devolve a gravação ao custo
-- que o índice existia para evitar — e é o preço certo. Reproduzir e
-- navegar, que é a maior parte do tempo, não escreve nada e continua
-- aproveitando o índice inteiro.
local idx = { valido = false, notas = {}, ccs = {} }

-- QUANTAS VEZES a timeline mudou. Não é um relógio: é um carimbo. Quem
-- guarda um resultado derivado das notas compara o carimbo e sabe, sem
-- reler nada, se o que tem na mão ainda vale.
local revisao = 0

--- Invalida o índice. Chamado sempre que a timeline muda.
function Timeline.invalidateIndex()
  idx.valido = false
  revisao = revisao + 1
end

--- O carimbo atual. Muda a cada escrita na timeline.
function Timeline.revision() return revisao end

-- O TAKE GUARDADO NO ÍNDICE PODE MORRER SEM AVISO.
--
-- O índice guarda o take de cada nota. Basta alguém mexer nos itens da
-- track por fora — outro script, um gerenciador de repertório, o próprio
-- usuário no arranjo — para esses ponteiros deixarem de valer, e aí a
-- primeira conversão de tique derruba o SCRIPT INTEIRO com
-- "MediaItem_Take expected". O índice não tem como ser avisado.
--
-- Então toda conversão passa por aqui: se o take morreu, o índice
-- inteiro vai fora e quem chamou desiste do caminho rápido — todas as
-- três consultas têm uma varredura direta de reserva, que relê os itens
-- e não depende de ponteiro nenhum.
--
-- Perder um quadro de espelho é um piscar. Fechar a janela é ficar sem
-- controle de luz no meio do show.
local function converterSeguro(fn, take, valor)
  local ok, v = pcall(fn, take, valor)
  if ok and type(v) == 'number' then return v end
  Timeline.invalidateIndex()
  return nil
end
--- Assinatura do PROJETO: muda quando o projeto muda.
--
--  Guarda duas coisas que o índice não tem como perceber sozinho.
--
--  O CONTADOR DE MUDANÇAS do REAPER cobre o que acontece POR FORA: outro
--  script, o usuário mexendo no arranjo, um item apagado à mão. Antes
--  isso era coberto por força bruta — `setTrack` jogava o índice fora a
--  cada revalidação, de dois em dois segundos, tivesse mudado algo ou
--  não. Um soluço regular no meio do desenho, que é exatamente como uma
--  pulada aparece. O contador diz a mesma coisa sem custo e na hora.
--
--  O ANDAMENTO cobre a tradução de tique para segundo, que o índice
--  agora guarda pronta. Mexer no BPM não muda tique nenhum, mas muda
--  onde cada um deles cai no tempo.
local function assinaturaProjeto()
  local r = api()
  local mudancas = r.GetProjectStateChangeCount
                   and r.GetProjectStateChangeCount(0) or 0
  local n = r.CountTempoTimeSigMarkers and r.CountTempoTimeSigMarkers(0) or 0
  local bpm = r.Master_GetTempo and r.Master_GetTempo() or 0
  return ('%s:%s:%s'):format(tostring(mudancas), tostring(n), tostring(bpm))
end

--- Relê o item e monta o índice, se preciso.
local function rebuildIndex()
  local sig = assinaturaProjeto()
  if idx.valido and idx.sig == sig then return end

  idx.notas, idx.ccs = {}, {}
  idx.valido = true
  idx.sig = sig

  local track = Timeline.track()
  if not track then return end

  local r = api()
  if not r.MIDI_GetNote or not r.MIDI_CountEvts then return end

  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local take = r.GetActiveTake(item)

    if take and r.TakeIsMIDI(take) then
      local noteCount, ccCount = select(2, r.MIDI_CountEvts(take))

      -- O TEMPO EM SEGUNDOS SAI DAQUI, uma vez por evento.
      --
      -- Antes cada consulta convertia tique para segundo com uma chamada
      -- ao REAPER POR EVENTO. As faixas consultam quatro vezes por
      -- segundo, e numa música programada são mais de mil eventos: quatro
      -- mil chamadas por segundo só para redesenhar o que não mudou. Era
      -- isso que dava as puladas na tela.
      -- SEM invalidar em caso de falha, ao contrário de converterSeguro:
      -- invalidar no meio da própria montagem faria a consulta seguinte
      -- montar tudo de novo, e a seguinte também, sem parar. Falhando,
      -- simplesmente não há cache — e quem consulta converte na hora,
      -- como antes.
      local function converterAqui(fn, take2, v)
        local ok2, res = pcall(fn, take2, v)
        if ok2 and type(res) == 'number' then return res end
        return nil
      end
      local conv = r.MIDI_GetProjTimeFromPPQPos
      for n = 0, (noteCount or 0) - 1 do
        local ok, _, _, s0, e0, _, pitch = r.MIDI_GetNote(take, n)
        if ok then
          local t0 = conv and converterAqui(conv, take, s0)
          local t1 = t0 and converterAqui(conv, take, e0)
          idx.notas[#idx.notas + 1] = {
            take = take, s = s0, e = e0, pitch = pitch,
            t0 = t0, t1 = t1,
            itemPos = pos, itemLen = len,
          }
        end
      end

      for n = 0, (ccCount or 0) - 1 do
        local ok, _, _, ccPPQ, _, _, msg2, msg3 = r.MIDI_GetCC(take, n)
        if ok then
          idx.ccs[#idx.ccs + 1] = {
            take = take, ppq = ccPPQ, cc = msg2, valor = msg3,
            t = conv and converterAqui(conv, take, ccPPQ) or nil,
            itemPos = pos, itemLen = len,
          }
        end
      end
    end
  end

  table.sort(idx.ccs, function(a, b) return a.ppq < b.ppq end)
end


--- Notas soando E valores de fader numa posição, numa varredura só.
--
--  soundingAt e ccValuesAt percorriam o item CADA UMA. Com o espelho
--  lendo quinze vezes por segundo, eram trinta varreduras completas por
--  segundo num item que pode ter centenas de eventos — e é isso que
--  derruba a taxa de quadros durante a reprodução.
--
--  @return table alturas, table valores de CC
function Timeline.stateAt(timeSeconds)
  return Timeline.soundingAt(timeSeconds), Timeline.ccValuesAt(timeSeconds)
end

--- Quais alturas estão soando numa posição, lendo o que foi gravado.
--
--  Serve para o retorno visual durante o play: os botões acendem
--  sozinhos conforme a programação passa pelo cursor, e você vê o que
--  está em execução sem olhar para o Lumikit.
--
--  @return table altura -> true
function Timeline.soundingAt(timeSeconds)
  local out = {}
  local track = Timeline.track()
  if not track then return out end

  rebuildIndex()

  local r = api()
  if #idx.notas > 0 and r.MIDI_GetPPQPosFromProjTime then
    local morreu = false
    for _, n in ipairs(idx.notas) do
      if timeSeconds >= n.itemPos and timeSeconds < n.itemPos + n.itemLen then
        local ppq = converterSeguro(r.MIDI_GetPPQPosFromProjTime, n.take, timeSeconds)
        if not ppq then morreu = true break end
        if n.s <= ppq and n.e > ppq then out[n.pitch] = true end
      end
    end
    -- Só devolve o que o índice respondeu se ele respondeu INTEIRO. Uma
    -- resposta pela metade seria pior que nenhuma: apagaria na tela
    -- controles que estão acesos de verdade.
    if not morreu then return out end
    out = {}
  end

  local r = api()
  if not r.MIDI_CountEvts or not r.MIDI_GetNote then return out end

  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')

    if timeSeconds >= pos and timeSeconds < pos + len then
      local take = r.GetActiveTake(item)
      if take and r.TakeIsMIDI(take) then
        local ppq = r.MIDI_GetPPQPosFromProjTime(take, timeSeconds)
        local _, noteCount = r.MIDI_CountEvts(take)
        for n = 0, (noteCount or 0) - 1 do
          local ok, _, _, sPPQ, ePPQ, _, pitch = r.MIDI_GetNote(take, n)
          if ok and sPPQ <= ppq and ePPQ > ppq then
            out[pitch] = true
          end
        end
      end
    end
  end

  return out
end

--- Onde ler para ver a ABERTURA de uma música, passando o Release All.
--
--  A primeira célula de cada música é reservada ao Release All (ver
--  Recorder.openSong): ali dentro a única coisa soando é o release, e o
--  que fica ligado a partir dali só começa na célula seguinte. Ler na
--  posição do cursor, portanto, mostra tudo apagado logo no ponto em que
--  mais interessa saber como a música abre.
--
--  RESPONDE PELA NOTA DO RELEASE, NÃO PELA GRADE DO PROJETO. Calcular a
--  célula a partir da grade atual erra sempre que a grade mudou depois
--  da gravação — e a grade é uma preferência de edição, que muda o tempo
--  todo. A nota do release, essa, tem o tamanho com que foi escrita.
--
--  Devolve MEIA CÉLULA adiante do fim do release, usando o próprio
--  comprimento dele como medida: parar bem na fronteira é arriscado,
--  porque a conversão tempo->tique não volta exata e um tique a menos
--  cai de volta dentro do release.
--
--  @param startTime início da música
--  @param pitch     altura do Release All
--  @return number|nil tempo em segundos, ou nil se não houver release
function Timeline.afterReleaseTime(startTime, pitch)
  local track = Timeline.track()
  if not track or not pitch then return nil end

  rebuildIndex()

  local r = api()
  if not r.MIDI_GetProjTimeFromPPQPos then return nil end

  for _, n in ipairs(idx.notas) do
    if n.pitch == pitch
       and startTime >= n.itemPos and startTime < n.itemPos + n.itemLen then
      local t0 = converterSeguro(r.MIDI_GetProjTimeFromPPQPos, n.take, n.s)
      local t1 = t0 and converterSeguro(r.MIDI_GetProjTimeFromPPQPos, n.take, n.e)
      -- Sem take válido não há resposta possível: quem chamou lê na
      -- posição do cursor, como fazia antes desta função existir.
      if not t1 then return nil end
      local celula = t1 - t0
      -- O release da ABERTURA, não um release gravado no meio da
      -- música: ele começa a menos de duas células do início. A folga
      -- de duas cobre o arredondamento à grade, que pode jogar a
      -- primeira célula para qualquer um dos lados do início da região.
      if celula > 0 and t1 > startTime
         and t0 - startTime < celula * 2 then
        return t1 + celula * 0.5
      end
    end
  end

  return nil
end

--- TUDO o que está gravado num trecho, em segundos.
--
--  Serve às faixas de programação (ver core/lanes.lua): elas mostram a
--  música inteira de uma vez, não o estado num instante, então precisam
--  dos eventos com início e fim — e em SEGUNDOS, que é a unidade da
--  régua na tela.
--
--  Notas que ATRAVESSAM a borda entram, cortadas pela borda: uma cor que
--  vem da música anterior está acesa nesta, e mostrá-la é o ponto.
--
--  @return table { notas = { {pitch, t0, t1} }, ccs = { {cc, t, valor} } }
function Timeline.eventsIn(startTime, endTime)
  local out = { notas = {}, ccs = {} }
  local track = Timeline.track()
  if not track or not startTime or not endTime then return out end

  rebuildIndex()

  local r = api()
  if not r.MIDI_GetProjTimeFromPPQPos then return out end

  for _, n in ipairs(idx.notas) do
    if n.itemPos < endTime and n.itemPos + n.itemLen > startTime then
      -- JÁ CONVERTIDO no índice; sem cache, converte aqui como antes.
      local t0 = n.t0 or converterSeguro(r.MIDI_GetProjTimeFromPPQPos, n.take, n.s)
      local t1 = n.t1
        or (t0 and converterSeguro(r.MIDI_GetProjTimeFromPPQPos, n.take, n.e))
      if not t1 then return out end
      if t1 > startTime and t0 < endTime then
        out.notas[#out.notas + 1] = {
          pitch = n.pitch,
          t0 = math.max(t0, startTime),
          t1 = math.min(t1, endTime),
          -- O tempo REAL de início, sem o corte da borda: é por ele que
          -- a edição reencontra a nota, e cortar aqui faria a busca
          -- procurar por uma posição que não existe no item.
          origem = t0,
        }
      end
    end
  end

  for _, c in ipairs(idx.ccs) do
    if c.itemPos < endTime and c.itemPos + c.itemLen > startTime then
      local t = c.t
        or converterSeguro(r.MIDI_GetProjTimeFromPPQPos, c.take, c.ppq)
      if not t then return out end
      if t >= startTime and t <= endTime then
        out.ccs[#out.ccs + 1] = { cc = c.cc, t = t, valor = c.valor }
      end
    end
  end

  return out
end

--- Acha uma nota pela altura e pelo instante em que ela começa.
--
--  A EDIÇÃO NÃO PODE GUARDAR ÍNDICE DE NOTA. O índice muda a cada
--  apagar e a cada inserir, e um índice guardado de um quadro para o
--  outro passa a apontar para OUTRA nota — que seria então esticada ou
--  apagada no lugar da escolhida. Reencontrar pela posição é a única
--  identificação estável.
--
--  @return take, indice, s0, e0  ou nil
local function acharNotaEm(pitch, tempoInicio)
  local track = Timeline.track()
  if not track or not pitch then return nil end

  local r = api()
  if not r.MIDI_GetNote or not r.MIDI_CountEvts then return nil end
  if not r.MIDI_GetPPQPosFromProjTime then return nil end

  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')

    if tempoInicio >= pos - 0.001 and tempoInicio < pos + len + 0.001 then
      local take = r.GetActiveTake(item)
      if take and r.TakeIsMIDI(take) then
        local alvo = r.MIDI_GetPPQPosFromProjTime(take, tempoInicio)
        local _, count = r.MIDI_CountEvts(take)
        for n = 0, (count or 0) - 1 do
          local ok, _, _, s0, e0, _, p = r.MIDI_GetNote(take, n)
          -- Meio tique de folga: a ida e volta segundos->tique não
          -- fecha exata, e exigir igualdade não acharia nada.
          if ok and p == pitch and math.abs(s0 - alvo) < 2 then
            return take, n, s0, e0
          end
        end
      end
    end
  end
  return nil
end

--- Muda o início e o fim de uma nota já gravada.
--
--  @param pitch        altura da nota
--  @param tempoInicio  onde ela começa HOJE, para reencontrá-la
--  @param novoT0       novo início, em segundos
--  @param novoT1       novo fim, em segundos
--  @return boolean deu certo?
function Timeline.setNoteSpan(pitch, tempoInicio, novoT0, novoT1)
  local take, n = acharNotaEm(pitch, tempoInicio)
  if not take then return false end

  local r = api()
  if not r.MIDI_SetNote then return false end

  local p0 = r.MIDI_GetPPQPosFromProjTime(take, novoT0)
  local p1 = r.MIDI_GetPPQPosFromProjTime(take, novoT1)
  if p1 <= p0 then return false end

  r.MIDI_SetNote(take, n, nil, nil, p0, p1, nil, nil, nil, true)
  if r.MIDI_Sort then r.MIDI_Sort(take) end
  Timeline.invalidateIndex()
  return true
end

--- Cria uma nota nova, do zero.
--
--  FALTAVA A PONTA DE CRIAR. Havia como esticar, encurtar, juntar e
--  apagar uma nota — tudo sobre notas que já existiam —, e a única forma
--  de fazer a primeira aparecer era gravando. Quem edita à mão precisa
--  acrescentar tanto quanto precisa tirar.
--
--  A altura e o canal vêm do controle da Tela Personalizada, como em
--  toda escrita daqui: o LumiBridge não inventa nota, ele escreve a nota
--  daquele botão.
--
--  @return boolean deu certo?
function Timeline.inserirNota(pitch, canal, t0, t1)
  local track = Timeline.track()
  if not track or not pitch then return false end

  local r = api()
  if not r.MIDI_InsertNote or not r.MIDI_GetPPQPosFromProjTime then
    return false
  end

  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')

    if t0 >= pos - 0.001 and t0 < pos + len + 0.001 then
      local take = r.GetActiveTake(item)
      if take and r.TakeIsMIDI(take) then
        -- NÃO PASSA DO FIM DO ITEM: uma nota que termina depois dele não
        -- soa, e some da lista sem explicação.
        local fim = math.min(t1, pos + len)
        local p0 = r.MIDI_GetPPQPosFromProjTime(take, t0)
        local p1 = r.MIDI_GetPPQPosFromProjTime(take, fim)
        if p1 <= p0 then return false end
        r.MIDI_InsertNote(take, false, false, p0, p1,
                          (canal or 1) - 1, pitch, 127, true)
        if r.MIDI_Sort then r.MIDI_Sort(take) end
        Timeline.invalidateIndex()
        return true
      end
    end
  end
  return false
end

--- Apaga uma nota já gravada.
--
--  @return boolean deu certo?
function Timeline.deleteNoteAt(pitch, tempoInicio)
  local take, n = acharNotaEm(pitch, tempoInicio)
  if not take then return false end

  local r = api()
  if not r.MIDI_DeleteNote then return false end

  r.MIDI_DeleteNote(take, n)
  if r.MIDI_Sort then r.MIDI_Sort(take) end
  Timeline.invalidateIndex()
  return true
end

--- Apaga os itens MIDI de um trecho: a programação inteira daquela
--  música na track escolhida.
--
--  APAGA O ITEM, não os eventos dentro dele. Limpar por dentro deixaria
--  um item vazio no lugar, e a diferença aparece no REC seguinte: uma
--  região "com item mas sem notas" não é o mesmo que uma região limpa
--  para quem decide se o preparo automático deve rodar
--  (Timeline.countNotesIn conta notas, mas o item vazio confunde a
--  leitura de quem olha a track no REAPER).
--
--  @return integer quantos itens foram apagados
function Timeline.deleteRegionItems(startTime, endTime)
  local track = Timeline.track()
  if not track or not startTime or not endTime then return 0 end

  local r = api()
  if not r.DeleteTrackMediaItem then return 0 end

  -- DE TRÁS PARA A FRENTE: apagar renumera os itens seguintes, e um
  -- laço crescente pularia um a cada remoção.
  local apagados = 0
  for i = r.CountTrackMediaItems(track) - 1, 0, -1 do
    local item = r.GetTrackMediaItem(track, i)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
    -- Sobreposição real, com folga de meio quadro: um item que apenas
    -- encosta na borda da região é da música vizinha.
    if pos < endTime - 0.01 and pos + len > startTime + 0.01 then
      if r.DeleteTrackMediaItem(track, item) then apagados = apagados + 1 end
    end
  end

  if apagados > 0 then
    Timeline.resetLive()
    Timeline.clearTails()
    Timeline.invalidateIndex()
  end
  return apagados
end

--- Acha um ponto de automação pelo controlador e pelo instante.
--
--  Pela POSIÇÃO, como acharNotaEm e pelo mesmo motivo: o índice de um
--  evento muda a cada inserção e a cada remoção, e um índice guardado de
--  um quadro para o outro passa a apontar para outro ponto — que seria
--  então movido ou apagado no lugar do escolhido.
--
--  @return take, indice  ou nil
local function acharCCEm(cc, tempo)
  local track = Timeline.track()
  if not track or not cc then return nil end

  local r = api()
  if not r.MIDI_GetCC or not r.MIDI_CountEvts then return nil end
  if not r.MIDI_GetPPQPosFromProjTime then return nil end

  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')

    if tempo >= pos - 0.001 and tempo < pos + len + 0.001 then
      local take = r.GetActiveTake(item)
      if take and r.TakeIsMIDI(take) then
        local alvo = r.MIDI_GetPPQPosFromProjTime(take, tempo)
        local _, _, count = r.MIDI_CountEvts(take)
        for n = 0, (count or 0) - 1 do
          local ok, _, _, ppq, _, _, msg2 = r.MIDI_GetCC(take, n)
          if ok and msg2 == cc and math.abs(ppq - alvo) < 2 then
            return take, n
          end
        end
      end
    end
  end
  return nil
end

--- Move um ponto de automação no tempo e/ou no valor.
--  @return boolean deu certo?
function Timeline.setCCPoint(cc, canal, tempoAtual, novoTempo, novoValor)
  local take, n = acharCCEm(cc, tempoAtual)
  if not take then return false end

  local r = api()
  if not r.MIDI_SetCC then return false end

  local ppq = r.MIDI_GetPPQPosFromProjTime(take, novoTempo)
  -- O canal do .form é 1-based; o do REAPER é 0-based.
  r.MIDI_SetCC(take, n, nil, nil, ppq, nil, (canal or 1) - 1, cc,
               math.floor(novoValor + 0.5), true)
  if r.MIDI_Sort then r.MIDI_Sort(take) end
  Timeline.invalidateIndex()
  return true
end

--- Apaga um ponto de automação.
--  @return boolean deu certo?
function Timeline.deleteCCAt(cc, tempo)
  local take, n = acharCCEm(cc, tempo)
  if not take then return false end

  local r = api()
  if not r.MIDI_DeleteCC then return false end

  r.MIDI_DeleteCC(take, n)
  if r.MIDI_Sort then r.MIDI_Sort(take) end
  Timeline.invalidateIndex()
  return true
end

--- Valores de Control Change vigentes numa posição.
--
--  Para cada CC, o ÚLTIMO valor escrito até aquele ponto — é assim que
--  um controlador se comporta: o valor vale até alguém mudar.
--
--  @return table cc -> valor 0..127
function Timeline.ccValuesAt(timeSeconds)
  local out = {}
  local track = Timeline.track()
  if not track then return out end

  rebuildIndex()

  local r = api()
  if #idx.ccs > 0 and r.MIDI_GetPPQPosFromProjTime then
    local antes, depois = {}, {}
    local morreu = false
    for _, c in ipairs(idx.ccs) do
      if timeSeconds >= c.itemPos and timeSeconds < c.itemPos + c.itemLen then
        local ppq = converterSeguro(r.MIDI_GetPPQPosFromProjTime, c.take, timeSeconds)
        if not ppq then morreu = true break end
        if c.ppq <= ppq then
          antes[c.cc] = c
        elseif not depois[c.cc] then
          depois[c.cc] = c
        end
      end
    end

    -- Take morto: cai para a varredura direta, LOGO ABAIXO. Sem
    -- recursão: chamar esta função de novo tentaria o índice outra vez,
    -- e um take que morre a cada reconstrução daria laço infinito no
    -- meio do show.
    if not morreu then
      for cc, a in pairs(antes) do
        local d = depois[cc]
        local ppq = d and d.ppq > a.ppq
          and converterSeguro(r.MIDI_GetPPQPosFromProjTime, a.take, timeSeconds)
        if ppq then
          local t = (ppq - a.ppq) / (d.ppq - a.ppq)
          if t < 0 then t = 0 elseif t > 1 then t = 1 end
          local suave = t * t * (3 - 2 * t)
          out[cc] = math.floor(a.valor + (d.valor - a.valor) * suave + 0.5)
        else
          out[cc] = a.valor
        end
      end
      return out
    end
    out = {}
  end

  local r = api()
  if not r.MIDI_CountEvts or not r.MIDI_GetCC then return out end

  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')

    if timeSeconds >= pos and timeSeconds < pos + len then
      local take = r.GetActiveTake(item)
      if take and r.TakeIsMIDI(take) then
        local ppq = r.MIDI_GetPPQPosFromProjTime(take, timeSeconds)
        local _, _, ccCount = r.MIDI_CountEvts(take)

        -- INTERPOLA entre o ponto anterior e o seguinte.
        --
        -- A automação de um fader tem só DOIS pontos: onde o movimento
        -- começou e onde parou. O REAPER desenha a rampa entre eles na
        -- reprodução, mas os eventos gravados são apenas os dois.
        --
        -- Lendo só o ponto anterior, o fader da tela ficava parado no
        -- valor inicial e saltava para o final — 0 ou 100, nunca o
        -- caminho. Aqui refazemos a rampa que o REAPER faz.
        local antes, depois = {}, {}

        for n = 0, (ccCount or 0) - 1 do
          local ok, _, _, ccPPQ, _, _, msg2, msg3 = r.MIDI_GetCC(take, n)
          if ok then
            if ccPPQ <= ppq then
              local a = antes[msg2]
              if not a or ccPPQ >= a.ppq then
                antes[msg2] = { ppq = ccPPQ, valor = msg3 }
              end
            else
              local d = depois[msg2]
              if not d or ccPPQ < d.ppq then
                depois[msg2] = { ppq = ccPPQ, valor = msg3 }
              end
            end
          end
        end

        for cc, a in pairs(antes) do
          local d = depois[cc]
          if d and d.ppq > a.ppq then
            -- Curva "slow start/end": o mesmo formato usado ao gravar.
            local t = (ppq - a.ppq) / (d.ppq - a.ppq)
            if t < 0 then t = 0 elseif t > 1 then t = 1 end
            local suave = t * t * (3 - 2 * t)
            out[cc] = math.floor(a.valor + (d.valor - a.valor) * suave + 0.5)
          else
            out[cc] = a.valor
          end
        end
      end
    end
  end

  return out
end

function Timeline.resetStats()
  Timeline.notesWritten = 0
  Timeline.ccWritten    = 0
  Timeline.lastError    = nil
end

return Timeline
]=], "@midi/timeline.lua"))(...)
end

-- ============================ midi.transport
package.preload["midi.transport"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / midi/transport.lua

  Controle de transporte e navegação: play, pause, posição e regiões.

  POR QUE EXISTE
    Programar iluminação é repetir o mesmo trecho muitas vezes: tocar,
    ouvir, ajustar, voltar, tocar de novo. Ter de alternar para a janela
    do REAPER a cada uma dessas voltas quebra o ritmo do trabalho.

    Com este módulo, o play, a barra de posição e o salto entre regiões
    ficam dentro da janela do LumiBridge.

  ONDE SE ENCAIXA
    É a camada que fala com o REAPER sobre TEMPO. midi/timeline.lua fala
    sobre ESCRITA. A separação mantém cada arquivo pequeno e deixa claro
    quem mexe em quê.
------------------------------------------------------------------------]]

local Transport = {}

Transport.backend = nil     -- injetável nos testes

local function api()
  return Transport.backend or reaper
end

-- ---------------------------------------------------------------- estado

--- Está tocando?
function Transport.isPlaying()
  return (api().GetPlayState() & 1) == 1
end

--- Está pausado? (pausa é diferente de parado: a posição é preservada)
function Transport.isPaused()
  return (api().GetPlayState() & 2) == 2
end

--- Está gravando no REAPER? Não confundir com a gravação do LumiBridge.
function Transport.isRecording()
  return (api().GetPlayState() & 4) == 4
end

--- Posição atual em segundos: do play se estiver tocando, senão do cursor.
function Transport.position()
  local r = api()
  if Transport.isPlaying() then
    if r.GetPlayPosition2 then return r.GetPlayPosition2() end
    return r.GetPlayPosition()
  end
  return r.GetCursorPosition()
end

--- Duração do projeto em segundos.
function Transport.length()
  local r = api()
  if r.GetProjectLength then
    local len = r.GetProjectLength(0)
    if len and len > 0 then return len end
  end
  return 0
end

-- ---------------------------------------------------------------- ações

function Transport.play()  api().Main_OnCommand(1007, 0) end
function Transport.pause() api().Main_OnCommand(1008, 0) end
function Transport.stop()  api().Main_OnCommand(1016, 0) end

--- Alterna entre tocar e pausar (Ctrl+Espaço no REAPER).
function Transport.togglePlayPause()
  api().Main_OnCommand(40073, 0)
end

--- Alterna entre tocar e PARAR, que é o Espaço do REAPER.
--  Parar volta ao início do trecho; pausar mantém a posição.
function Transport.togglePlayStop()
  api().Main_OnCommand(40044, 0)
end

--- Desfaz a última ação do projeto (o mesmo Ctrl+Z do REAPER).
function Transport.undo() api().Main_OnCommand(40029, 0) end

--- Refaz a última ação desfeita.
function Transport.redo() api().Main_OnCommand(40030, 0) end

--- Descrição do que será desfeito, para mostrar na dica do botão.
function Transport.undoLabel()
  local r = api()
  if not r.Undo_CanUndo2 then return nil end
  local ok, texto = pcall(r.Undo_CanUndo2, 0)
  if ok and texto and texto ~= '' then return texto end
  return nil
end

function Transport.redoLabel()
  local r = api()
  if not r.Undo_CanRedo2 then return nil end
  local ok, texto = pcall(r.Undo_CanRedo2, 0)
  if ok and texto and texto ~= '' then return texto end
  return nil
end

--- Move o cursor para uma posição em segundos.
--  @param seek levar o play junto quando estiver tocando
function Transport.setPosition(seconds, seek)
  local r = api()
  if seconds < 0 then seconds = 0 end
  r.SetEditCurPos(seconds, true, seek ~= false)
end

-- --------------------------------------------------------------- regiões

--- Lista as regiões e marcadores do projeto.
--
--  Regiões têm início e fim; marcadores são só um ponto. As duas coisas
--  servem para navegar, então vêm na mesma lista, diferenciadas pelo
--  campo isRegion.
--
--  @return table { { name, startTime, endTime, isRegion, color }, ... }
function Transport.regions()
  local r = api()
  local out = {}
  if not r.CountProjectMarkers then return out end

  local _, markers, regions = r.CountProjectMarkers(0)
  local total = (markers or 0) + (regions or 0)

  for i = 0, total - 1 do
    local ok, isRegion, pos, rgnEnd, name, index, color =
      r.EnumProjectMarkers3(0, i)
    if ok and ok ~= 0 then
      out[#out + 1] = {
        name      = (name and name ~= '') and name
                    or ((isRegion and 'Região ' or 'Marca ') .. tostring(index)),
        startTime = pos,
        endTime   = isRegion and rgnEnd or pos,
        isRegion  = isRegion and true or false,
        index     = index,
        color     = color,
      }
    end
  end

  table.sort(out, function(a, b) return a.startTime < b.startTime end)
  return out
end

--- Região que contém uma posição. Marcadores não contam.
function Transport.regionAt(seconds, list)
  for _, rg in ipairs(list or Transport.regions()) do
    if rg.isRegion and seconds >= rg.startTime and seconds < rg.endTime then
      return rg
    end
  end
  return nil
end

--- Salta para uma região e, opcionalmente, prepara o trecho de trabalho.
--
--  @param loop  definir a seleção de tempo na região, para repetir só ela
function Transport.gotoRegion(region, loop)
  if not region then return end
  local r = api()
  Transport.setPosition(region.startTime, true)
  if loop and region.isRegion and r.GetSet_LoopTimeRange then
    r.GetSet_LoopTimeRange(true, true, region.startTime, region.endTime, false)
  end
end

--- Bordas cruas da seleção de tempo atual, sem casar com região nenhuma.
--
--  Existe separada de `regionFromTimeSelection` para quem precisa saber
--  se a seleção MUDOU de um quadro para o outro (ver uso em ui/window.lua
--  — distinguir uma seleção nova de uma seleção antiga que só continua
--  parada ali, deixada por outra ferramenta).
--
--  @return selStart, selEnd, ou nil se não há seleção de tempo
function Transport.timeSelection()
  local r = api()
  if not r.GetSet_LoopTimeRange then return nil end

  local ok, selStart, selEnd = pcall(r.GetSet_LoopTimeRange, false, false, 0, 0, false)
  if not ok or not selStart or not selEnd or selEnd <= selStart then
    return nil
  end
  return selStart, selEnd
end

--- A região que corresponde à seleção de tempo, se houver uma.
--
--  Selecionar o trecho da música no REAPER é um ATO do usuário, e por
--  isso pode trocar a música de trabalho. Mover o cursor não é.
--- @param lista opcional: regiões já lidas, para não reler o projeto
function Transport.regionFromTimeSelection(lista)
  local selStart, selEnd = Transport.timeSelection()
  if not selStart then return nil end

  -- Reaproveita a lista já montada. Percorrer os marcadores do projeto
  -- é caro num repertório com centenas de músicas, e fazer isso três
  -- vezes por ciclo derrubava a taxa de quadros.
  for _, rg in ipairs(lista or Transport.regions()) do
    if rg.isRegion
       and math.abs(rg.startTime - selStart) < 0.05
       and math.abs(rg.endTime - selEnd) < 0.05 then
      return rg
    end
  end
  return nil
end

--- A região em que se está trabalhando.
--
--  Regra de desempate, nesta ordem:
--    1. Se a seleção de tempo coincide com uma região, é ela. É o que
--       acontece quando se clica numa região no gerenciador ou se usa
--       "Repetir região" da barra.
--    2. Senão, a região sob o cursor de edição.
--
--  O fluxo do usuário é uma música por vez, e a música é uma região.
--  @return região ou nil
--- @param lista opcional: regiões já lidas, para não reler o projeto
function Transport.currentRegion(lista)
  local r = api()
  local list = lista or Transport.regions()

  if r.GetSet_LoopTimeRange then
    local ok, selStart, selEnd = pcall(r.GetSet_LoopTimeRange, false, false, 0, 0, false)
    if ok and selStart and selEnd and selEnd > selStart then
      for _, rg in ipairs(list) do
        if rg.isRegion
           and math.abs(rg.startTime - selStart) < 0.05
           and math.abs(rg.endTime - selEnd) < 0.05 then
          return rg
        end
      end
    end
  end

  return Transport.regionAt(r.GetCursorPosition(), list)
end

--- Localiza uma track pelo nome. Usada para achar a track da música.
function Transport.findTrackByName(name)
  local r = api()
  local alvo = (name or ''):upper()
  for i = 0, r.CountTracks(0) - 1 do
    local track = r.GetTrack(0, i)
    local _, nome = r.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
    if (nome or ''):upper() == alvo then return track, i end
  end
  return nil
end

-- ------------------------------------------------------------- formatação

--- Segundos em mm:ss.d, para exibir na barra.
function Transport.formatTime(seconds)
  seconds = math.max(0, seconds or 0)
  local minutes = math.floor(seconds / 60)
  local rest    = seconds - minutes * 60
  return ('%d:%04.1f'):format(minutes, rest)
end

return Transport
]=], "@midi/transport.lua"))(...)
end

-- ============================ ui.imgui_compat
package.preload["ui.imgui_compat"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / ui/imgui_compat.lua

  Camada de compatibilidade do ReaImGui.

  Por que isso existe:
    O ReaImGui mudou de API entre versões. Até a 0.9 as funções viviam
    como reaper.ImGui_Alguma(). A partir da 0.9 existe um "shim" oficial
    que devolve uma tabela ImGui.Alguma(), e na 0.10 o estilo antigo foi
    removido.

    Este módulo devolve SEMPRE uma tabela no estilo novo (ImGui.Alguma),
    não importa qual versão o usuário tenha instalada. Assim o resto do
    projeto escreve num estilo só e não quebra quando o usuário atualizar.
------------------------------------------------------------------------]]

local Compat = {}

Compat.MIN_VERSION = '0.9'

--- Tenta carregar o ReaImGui.
--  @return table|nil  a tabela ImGui, ou nil + mensagem de erro
function Compat.load()
  -- Caminho preferido: shim oficial (ReaImGui 0.9 em diante).
  if reaper.ImGui_GetBuiltinPath then
    local ok, path = pcall(reaper.ImGui_GetBuiltinPath)
    if ok and path then
      package.path = path .. '/?.lua;' .. package.path
      local loaded, imgui = pcall(function()
        return require('imgui')(Compat.MIN_VERSION)
      end)
      if loaded and imgui then return imgui end
    end
  end

  -- Caminho legado: proxy que remove o prefixo ImGui_ sob demanda.
  if reaper.ImGui_CreateContext then
    return setmetatable({}, {
      __index = function(t, key)
        local fn = reaper['ImGui_' .. key]
        if fn then rawset(t, key, fn) end
        return fn
      end,
    })
  end

  return nil, table.concat({
    'A extensão ReaImGui não foi encontrada.',
    '',
    'O LumiBridge usa o ReaImGui para desenhar a interface.',
    'Para instalar:',
    '',
    '  1. Menu Extensions > ReaPack > Browse packages',
    '  2. Procure por "ReaImGui"',
    '  3. Instale "ReaImGui: ReaScript binding for Dear ImGui"',
    '  4. Reinicie o REAPER e rode o LumiBridge de novo',
  }, '\n')
end

--- Lê um campo do ImGui sem nunca lançar erro.
--
--  O shim oficial do ReaImGui é ESTRITO: acessar um campo inexistente
--  lança erro em vez de devolver nil, para pegar erros de digitação.
--  Isso é bom, mas impede o teste ingênuo `if ImGui.Alguma ~= nil then`,
--  que é justamente como se detecta a versão disponível.
--
--  Toda sondagem de campo opcional no projeto deve passar por aqui.
function Compat.get(ImGui, name)
  local ok, value = pcall(function() return ImGui[name] end)
  if ok then return value end
  return nil
end

--- Verifica se um campo existe nesta versão do ReaImGui.
--- O ImGui tem este campo?
--
--  Sempre via Compat.get: o shim do ReaImGui LANÇA ERRO ao acessar um
--  campo inexistente, então testar com `if ImGui.Campo then` é o que
--  derruba o script.
function Compat.has(ImGui, name)
  return Compat.get(ImGui, name) ~= nil
end

--- Traduz um código de tecla do .form para a constante de tecla do ImGui.
--
--  O Lumikit grava os atalhos como códigos de tecla virtual do Windows:
--  65..90 são A..Z, 48..57 são 0..9, 112..123 são F1..F12. O ImGui usa
--  constantes nomeadas (Key_A, Key_F1). Esta função faz a ponte.
--
--  @return número da constante, ou nil se a tecla não for suportada
function Compat.keyFromCode(ImGui, code)
  code = tonumber(code)
  if not code then return nil end

  local name
  if code >= 65 and code <= 90 then
    name = 'Key_' .. string.char(code)              -- A..Z
  elseif code >= 48 and code <= 57 then
    name = 'Key_' .. (code - 48)                    -- 0..9
  elseif code >= 112 and code <= 123 then
    name = 'Key_F' .. (code - 111)                  -- F1..F12
  elseif code == 32 then
    name = 'Key_Space'
  else
    return nil
  end

  local value = Compat.get(ImGui, name)
  if type(value) == 'function' then
    local ok, resolved = pcall(value)
    return ok and resolved or nil
  end
  return value
end

--- Nome legível de um código de tecla, para exibir na interface.
function Compat.keyName(code)
  code = tonumber(code)
  if not code then return nil end
  if code >= 65 and code <= 90 then return string.char(code) end
  if code >= 48 and code <= 57 then return tostring(code - 48) end
  if code >= 112 and code <= 123 then return 'F' .. (code - 111) end
  if code == 32 then return 'Espaço' end
  return ('tecla %d'):format(code)
end

--- Combina várias flags de janela pelo nome, ignorando as ausentes.
--  Uma flag inexistente na versão instalada não pode derrubar a janela.
function Compat.windowFlags(ImGui, names)
  local flags = 0
  for _, name in ipairs(names) do
    flags = flags | Compat.const(ImGui, name, 0)
  end
  return flags
end

--- Lê uma constante do ImGui, seja ela função ou valor.
--
--  Até a 0.9 as constantes eram funções: ImGui.Cond_FirstUseEver().
--  Na 0.10 viraram valores diretos: ImGui.Cond_FirstUseEver.
--  Este resolvedor aceita as duas formas.
--
--  @param fallback valor usado se a constante não existir nesta versão
function Compat.const(ImGui, name, fallback)
  local value = Compat.get(ImGui, name)
  if type(value) == 'function' then
    local ok, resolved = pcall(value)
    if ok then return resolved end
    return fallback or 0
  end
  if value == nil then return fallback or 0 end
  return value
end

--- Anexa um objeto (fonte) ao contexto, tolerando o nome antigo.
function Compat.attach(ImGui, ctx, object)
  local attach = Compat.get(ImGui, 'Attach') or Compat.get(ImGui, 'AttachFont')
  if attach then return attach(ctx, object) end
end

--- Traduz um código de tecla do .form para a constante de tecla do ImGui.
--
--  O Lumikit grava os atalhos como códigos de tecla virtual do Windows:
--  65..90 são A..Z, 48..57 são 0..9, 112..123 são F1..F12. O ImGui usa
--  constantes nomeadas (Key_A, Key_F1). Esta função faz a ponte.
--
--  @return número da constante, ou nil se a tecla não for suportada
function Compat.keyFromCode(ImGui, code)
  code = tonumber(code)
  if not code then return nil end

  local name
  if code >= 65 and code <= 90 then
    name = 'Key_' .. string.char(code)              -- A..Z
  elseif code >= 48 and code <= 57 then
    name = 'Key_' .. (code - 48)                    -- 0..9
  elseif code >= 112 and code <= 123 then
    name = 'Key_F' .. (code - 111)                  -- F1..F12
  elseif code == 32 then
    name = 'Key_Space'
  else
    return nil
  end

  local value = Compat.get(ImGui, name)
  if type(value) == 'function' then
    local ok, resolved = pcall(value)
    return ok and resolved or nil
  end
  return value
end

--- Nome legível de um código de tecla, para exibir na interface.
function Compat.keyName(code)
  code = tonumber(code)
  if not code then return nil end
  if code >= 65 and code <= 90 then return string.char(code) end
  if code >= 48 and code <= 57 then return tostring(code - 48) end
  if code >= 112 and code <= 123 then return 'F' .. (code - 111) end
  if code == 32 then return 'Espaço' end
  return ('tecla %d'):format(code)
end

--- Combina várias flags de janela pelo nome, ignorando as ausentes.
--  Uma flag inexistente na versão instalada não pode derrubar a janela.
function Compat.windowFlags(ImGui, names)
  local flags = 0
  for _, name in ipairs(names) do
    flags = flags | Compat.const(ImGui, name, 0)
  end
  return flags
end

return Compat
]=], "@ui/imgui_compat.lua"))(...)
end

-- ============================ ui.theme
package.preload["ui.theme"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / ui/theme.lua

  Conversão de cores do Modelo para o ImGui e gerência de fontes.

  Este módulo é a única ponte entre as cores "puras" do Modelo
  ({r,g,b} 0..255) e o formato inteiro 0xRRGGBBAA que o ImGui usa.

  Sobre as fontes:
    O ImGui precisa que cada tamanho de fonte seja criado e anexado ao
    contexto antes do uso. Como o .form traz tamanhos arbitrários
    (11, 20 e 30 no arquivo de referência) e o zoom muda esses valores,
    mantemos uma "escada" de tamanhos e escolhemos o mais próximo.

    Escolha consciente: fonte ligeiramente aproximada em zoom não-padrão
    é preferível a reconstruir o atlas de fontes a cada mudança de zoom,
    o que causaria travadas visíveis.
------------------------------------------------------------------------]]

local Compat = require('ui.imgui_compat')

local Theme = {}

--- Escada de tamanhos de fonte pré-criados.
Theme.FONT_LADDER = {
  8, 9, 10, 11, 12, 13, 14, 16, 18, 20, 22, 24, 26, 28, 30, 34, 38, 44, 52
}

-- Cores da moldura do LumiBridge (fora da área do layout).
--
-- CANVAS_BG (0x1E1E1E) foi removida: era um retângulo pintado debaixo
-- de todo o layout, num cinza que não vem do .form nem desta paleta.
-- O fundo da janela já está atrás; pintar por cima dele só criava uma
-- terceira cor que não é de ninguém.
Theme.HOVER_TINT  = 0.18   -- clareamento do controle sob o cursor
Theme.ACTIVE_RING = 0xFFFFFFFF
Theme.ORPHAN      = 0xB03030FF

--- Converte cor do Modelo para inteiro do ImGui.
function Theme.rgba(color, alpha)
  local a = math.floor((alpha or 1.0) * 255 + 0.5)
  return ((color.r & 0xFF) << 24)
       | ((color.g & 0xFF) << 16)
       | ((color.b & 0xFF) << 8)
       | (a & 0xFF)
end

--- Cria e anexa as fontes ao contexto. Chamado uma vez, na criação da janela.
--
--  Duas estratégias, escolhidas conforme a versão do ReaImGui:
--
--   'scalable'  (0.10 em diante) — uma fonte só. O tamanho é informado
--               no PushFont, então qualquer tamanho funciona e o zoom
--               fica perfeito. CreateFont não aceita mais tamanho ali:
--               o segundo argumento virou "flags" (negrito, itálico).
--
--   'ladder'    (até 0.9) — uma fonte assada por tamanho. Escolhemos a
--               mais próxima do pedido.
--
--  A presença de FontSize_Default distingue as duas: ela só existe na
--  versão que trata fontes como escaláveis.
function Theme.createFonts(ImGui, ctx)
  if Compat.has(ImGui, 'FontSize_Default') then
    local ok, font = pcall(ImGui.CreateFont, 'sans-serif')
    if ok and font then
      Compat.attach(ImGui, ctx, font)
      return { mode = 'scalable', font = font }
    end
  end

  local fonts = { mode = 'ladder', sizes = {} }
  for _, size in ipairs(Theme.FONT_LADDER) do
    local ok, font = pcall(ImGui.CreateFont, 'sans-serif', size)
    if ok and font then
      Compat.attach(ImGui, ctx, font)
      fonts.sizes[size] = font
    end
  end
  return fonts
end

--- Escolhe a fonte e o tamanho a empurrar para um tamanho pedido.
--  @return font, tamanhoParaEmpurrar
function Theme.pickFont(fonts, wanted)
  if fonts.mode == 'scalable' then
    return fonts.font, math.max(4, wanted)
  end

  local best, bestDiff = Theme.FONT_LADDER[1], math.huge
  for _, size in ipairs(Theme.FONT_LADDER) do
    local diff = math.abs(size - wanted)
    if diff < bestDiff then best, bestDiff = size, diff end
  end
  return fonts.sizes[best], best
end

--- Empurra uma fonte usando a assinatura correta para a versão.
--
--  Nunca chamar ImGui.PushFont diretamente: até a 0.9 ela aceita só
--  (ctx, font) e a partir da 0.10 exige (ctx, font, size). Errar a
--  contagem abre o diálogo de erro do REAPER mesmo sob pcall.
function Theme.pushFont(ImGui, ctx, fonts, size)
  local font, pushSize = Theme.pickFont(fonts, size)
  if not font then return false end
  if fonts.mode == 'scalable' then
    ImGui.PushFont(ctx, font, pushSize)
  else
    ImGui.PushFont(ctx, font)
  end
  return true
end

-- ------------------------------------------------------------- estilo

--- Paleta da interface do LumiBridge (a moldura, não o layout do .form).
Theme.UI = {
  bg          = 0x14161AFF,
  panel       = 0x1C1F26FF,
  panelHover  = 0x252932FF,
  panelActive = 0x2E333EFF,
  border      = 0x000000FF,
  text        = 0xD8DCE4FF,
  textDim     = 0x7A8290FF,
  accent      = 0x3D8BFDFF,
  accentHover = 0x5599FFFF,
  rec         = 0xE5484DFF,
  recHover    = 0xF06166FF,
  ok          = 0x46A758FF,
  warn        = 0xF5A524FF,
}

--- Aplica o estilo da janela. Devolve quantas cores e variáveis foram
--  empilhadas, para o chamador desempilhar o mesmo número.
--
--  O ImGui exige que todo Push tenha um Pop correspondente; empilhar sem
--  desempilhar corrompe o estado e o efeito vaza para os quadros
--  seguintes. Por isso as contagens são devolvidas em vez de fixadas.
--- @param quadrada  cantos retos (janela maximizada)
function Theme.push(ImGui, ctx, Compat, quadrada)
  local cores = {
    { 'Col_WindowBg',            Theme.UI.bg },
    { 'Col_ChildBg',             Theme.UI.bg },
    { 'Col_PopupBg',             Theme.UI.panel },
    -- A BORDA PRECISA SER VISTA. 0x2A2F3A é quase a cor do painel: como
    -- separador dentro do painel funciona, como contorno de um menu
    -- flutuando por cima some.
    { 'Col_Border',              0x3F4654FF },
    { 'Col_FrameBg',             Theme.UI.panel },
    { 'Col_FrameBgHovered',      Theme.UI.panelHover },
    { 'Col_FrameBgActive',       Theme.UI.panelActive },
    { 'Col_Button',              Theme.UI.panel },
    { 'Col_ButtonHovered',       Theme.UI.panelHover },
    { 'Col_ButtonActive',        Theme.UI.accent },
    { 'Col_Text',                Theme.UI.text },
    { 'Col_TextDisabled',        Theme.UI.textDim },
    { 'Col_CheckMark',           Theme.UI.accent },
    { 'Col_SliderGrab',          Theme.UI.accent },
    { 'Col_SliderGrabActive',    Theme.UI.accentHover },
    { 'Col_Header',              Theme.UI.panelHover },
    { 'Col_HeaderHovered',       Theme.UI.panelActive },
    { 'Col_HeaderActive',        Theme.UI.accent },
    { 'Col_TitleBg',             Theme.UI.bg },
    { 'Col_TitleBgActive',       Theme.UI.panel },
    { 'Col_Separator',           0x2A2F3AFF },
    { 'Col_ScrollbarBg',         Theme.UI.bg },
    { 'Col_ScrollbarGrab',       Theme.UI.panelHover },
  }

  local nCores = 0
  for _, c in ipairs(cores) do
    local id = Compat.const(ImGui, c[1], nil)
    if id and ImGui.PushStyleColor then
      local ok = pcall(ImGui.PushStyleColor, ctx, id, c[2])
      if ok then nCores = nCores + 1 end
    end
  end

  local vars = {
    { 'StyleVar_FrameRounding',   4 },
    { 'StyleVar_GrabRounding',    4 },
    -- CANTO RETO QUANDO MAXIMIZADA.
    --
    -- Arredondado, a janela mostra o que está atrás nos quatro cantos —
    -- e ocupando a tela inteira isso é o desktop aparecendo por buracos
    -- no canto. Nenhuma janela do sistema faz isso maximizada, e o olho
    -- percebe antes de saber por quê.
    { 'StyleVar_WindowRounding',  quadrada and 0 or 6 },
    { 'StyleVar_ChildRounding',   quadrada and 0 or 6 },
    { 'StyleVar_PopupRounding',   6 },
    -- BORDA NOS POPUPS.
    --
    -- Sem ela um menu é uma mancha da cor do painel sobre a cor do
    -- fundo, e as duas são vizinhas na escala de cinza: o menu não tem
    -- onde começar nem onde terminar. É o que fazia os menus parecerem
    -- inacabados — não era a cor, era a falta de contorno.
    { 'StyleVar_PopupBorderSize', 1 },
    { 'StyleVar_FrameBorderSize', 0 },
    { 'StyleVar_ScrollbarSize',   10 },
  }

  local nVars = 0
  for _, v in ipairs(vars) do
    local id = Compat.const(ImGui, v[1], nil)
    if id and ImGui.PushStyleVar then
      local ok = pcall(ImGui.PushStyleVar, ctx, id, v[2])
      if ok then nVars = nVars + 1 end
    end
  end

  -- Espaçamentos são pares (x, y) e usam outra assinatura.
  local pares = {
    { 'StyleVar_FramePadding',  7, 4 },
    { 'StyleVar_ItemSpacing',   7, 5 },
    -- SEM ESPAÇAMENTO EM VOLTA DA JANELA.
    --
    -- Era 9x7, e o ImGui reserva isso em volta de TODO o conteúdo: sobrava
    -- uma faixa da cor do fundo nas quatro bordas. Numa janela com
    -- decoração própria isso lê como falha de acabamento, e maximizada —
    -- com a barra de título descolada do canto da tela — fica gritante.
    --
    -- Quem precisa de folga passa a pedi-la onde precisa (ver o recuo da
    -- barra de transporte), em vez de o programa inteiro pagar por ela.
    { 'StyleVar_WindowPadding', 0, 0 },
  }
  for _, v in ipairs(pares) do
    local id = Compat.const(ImGui, v[1], nil)
    if id and ImGui.PushStyleVar then
      local ok = pcall(ImGui.PushStyleVar, ctx, id, v[2], v[3])
      if ok then nVars = nVars + 1 end
    end
  end

  return nCores, nVars
end

function Theme.pop(ImGui, ctx, nCores, nVars)
  if nVars and nVars > 0 and ImGui.PopStyleVar then
    pcall(ImGui.PopStyleVar, ctx, nVars)
  end
  if nCores and nCores > 0 and ImGui.PopStyleColor then
    pcall(ImGui.PopStyleColor, ctx, nCores)
  end
end

return Theme
]=], "@ui/theme.lua"))(...)
end

-- ============================ ui.icon_cache
package.preload["ui.icon_cache"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / ui/icon_cache.lua

  Transforma os ícones do .form em imagens que o ImGui sabe desenhar.

  POR QUE EXISTE UM CACHE
    Um ícone é um bitmap 32x32 = 1024 pixels. Desenhar pixel a pixel
    com retângulos daria mais de cem mil chamadas de desenho por quadro
    com os 101 botões deste layout — inviável.

    Convertendo cada ícone em PNG UMA vez e entregando ao ImGui como
    imagem, o desenho de cada botão vira uma única chamada.

  DUAS ROTAS ATÉ A IMAGEM
    Preferimos CreateImageFromMem, que recebe os bytes direto e não
    encosta no disco. Se a versão do ReaImGui não tiver essa função,
    caímos para gravar um arquivo temporário e usar CreateImage.

  O cache é invalidado ao carregar outro .form, porque os ícones vêm
  do arquivo — trocar de arquivo troca os ícones.
------------------------------------------------------------------------]]

local Compat = require('ui.imgui_compat')
local Icons  = require('core.icons')

local IconCache = {}

local images   = {}     -- chave -> imagem do ImGui (ou false se falhou)
local tempDir  = nil
local mode     = nil    -- 'mem' ou 'file', resolvido no primeiro uso
local failures = 0

--- Descarta tudo. Chamado ao carregar outro layout.
function IconCache.reset()
  images   = {}
  failures = 0
end

local function resolveTempDir()
  if tempDir then return tempDir end
  local base = os.getenv('TEMP') or os.getenv('TMP') or '/tmp'
  local sep  = package.config:sub(1, 1)
  tempDir = base .. sep .. 'LumiBridge_icons'
  if reaper and reaper.RecursiveCreateDirectory then
    reaper.RecursiveCreateDirectory(tempDir, 0)
  end
  return tempDir
end

--- Cria a imagem do ImGui a partir dos bytes de um PNG.
local function makeImage(ImGui, ctx, png, key)
  if mode == nil then
    mode = Compat.get(ImGui, 'CreateImageFromMem') and 'mem' or 'file'
  end

  local ok, img

  if mode == 'mem' then
    ok, img = pcall(ImGui.CreateImageFromMem, png)
    if not ok or not img then
      mode = 'file'          -- uma falha basta para migrar de rota
    end
  end

  if mode == 'file' and not img then
    local dir  = resolveTempDir()
    local sep  = package.config:sub(1, 1)
    local path = ('%s%s%s.png'):format(dir, sep, key)
    local f = io.open(path, 'wb')
    if not f then return nil end
    f:write(png)
    f:close()
    ok, img = pcall(ImGui.CreateImage, path)
    if not ok then img = nil end
  end

  if img then Compat.attach(ImGui, ctx, img) end
  return img
end

--- Devolve a imagem de um elemento, criando na primeira vez.
--  @return imagem do ImGui, ou nil se o elemento não tiver ícone
function IconCache.get(ImGui, ctx, element, active)
  local icon = Icons.forState(element, active)
  if not icon or not icon.pixels then return nil end

  -- A chave identifica o DESENHO, não o botão: dois botões que usam a
  -- mesma função compartilham a mesma imagem. O estado entra na chave
  -- porque ligado e desligado são bitmaps diferentes.
  local key = ('%s_%s'):format(
    tostring(element.functionIndex or element.tag or 0),
    active and 'on' or 'off')

  local cached = images[key]
  if cached ~= nil then
    if cached == false then return nil end
    return cached
  end

  local png = Icons.iconToPNG(icon.pixels)
  if not png then
    images[key] = false
    return nil
  end

  local img = makeImage(ImGui, ctx, png, key)
  if not img then
    images[key] = false
    failures = failures + 1
    return nil
  end

  images[key] = img
  return img
end

-- ------------------------------------------------------------------
-- ÍCONES DA BARRA (ui/glyphs.lua)
-- ------------------------------------------------------------------
-- Mesma rota dos ícones do .form — bytes de PNG viram imagem do ImGui,
-- uma chamada de desenho por botão. A diferença é a origem: ali o
-- bitmap vem do arquivo do usuário, aqui vem de uma máscara de
-- transparência embutida no projeto, e a cor entra na hora.
--
-- Ficam num cache SEPARADO do de cima porque não dependem do .form:
-- o IconCache.reset() de troca de arquivo não tem por que descartá-los.
local monos = {}
local monoFalhas = 0

--- Imagem de um ícone da barra, na cor pedida.
--
--  @param glyph  {lado, alfa} de ui/glyphs.lua
--  @param rgba   cor empacotada 0xRRGGBBAA (só o RGB é usado)
--  @return imagem do ImGui, ou nil se esta versão não souber criar
function IconCache.mono(ImGui, ctx, nome, glyph, rgba)
  if not glyph or not glyph.alfa then return nil end

  local r = (rgba >> 24) & 0xFF
  local g = (rgba >> 16) & 0xFF
  local b = (rgba >> 8) & 0xFF

  -- A cor entra na chave: o mesmo desenho em duas cores são duas
  -- imagens, e trocar de cor não pode devolver a imagem da anterior.
  local key = ('mono_%s_%02x%02x%02x'):format(nome, r, g, b)

  local cached = monos[key]
  if cached ~= nil then
    if cached == false then return nil end
    return cached
  end

  -- A máscara guarda só a transparência; o RGB é constante. Escrever
  -- a cor em cada pixel (inclusive nos transparentes) é o formato que
  -- Icons.toPNG espera, e é feito UMA vez por ícone.
  local cor = string.char(r, g, b)
  local pixels, n = {}, 0
  for i = 1, #glyph.alfa do
    n = n + 1
    pixels[n] = cor .. glyph.alfa:sub(i, i)
  end

  local png = Icons.toPNG(table.concat(pixels), glyph.lado, glyph.lado)
  local img = png and makeImage(ImGui, ctx, png, key)

  if not img then monoFalhas = monoFalhas + 1 end
  monos[key] = img or false
  return img
end

--- Quantos ícones da barra viraram imagem, e quantos falharam.
--
--  Existe para o tests/test_compat.lua poder AFIRMAR que os ícones da
--  barra realmente viraram imagem. Sem isso, um `mono` devolvendo nil
--  passaria em todos os testes e só apareceria como botão vazio na tela
--  do usuário — que foi exatamente o tipo de erro que já escapou daqui.
function IconCache.monoStats()
  local n = 0
  for _, img in pairs(monos) do
    if img then n = n + 1 end
  end
  return n, monoFalhas
end

--- Quantos ícones já foram convertidos, para diagnóstico.
function IconCache.stats()
  local n = 0
  for _ in pairs(images) do n = n + 1 end
  return n, failures, mode or 'indefinido'
end

return IconCache
]=], "@ui/icon_cache.lua"))(...)
end

-- ============================ ui.glyphs
package.preload["ui.glyphs"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / ui/glyphs.lua

  Os dois ícones da barra que não são desenhados à mão: o release e a
  engrenagem das configurações.

  REGRA DE ARQUITETURA:
    Só dados. Não referencia `reaper` nem `ImGui`. Quem transforma isto
    em imagem é ui/icon_cache.lua; quem desenha é ui/window.lua.

  ------------------------------------------------------------------
  POR QUE IMAGEM, E NÃO DESENHO
  ------------------------------------------------------------------
  Estes dois já foram tentados como geometria — arco e ponta de seta
  calculados na mão, e depois o contorno vetorizado recortado numa
  malha de triângulos. As duas rotas saíram feias no REAPER, e pelo
  mesmo motivo: o ImGui monta a suavização empurrando as arestas de
  CADA primitiva 0,5px para fora. Numa malha cheia de triângulo fino,
  isso vira farpa na silhueta inteira.

  Mas o projeto já sabia resolver isso desde sempre. Os 101 botões do
  .form mostram ícone porque ui/icon_cache.lua converte bitmap em PNG e
  entrega ao ImGui como imagem, com uma chamada de desenho por botão.
  Estes dois passam exatamente pela mesma rota — e por isso aparecem
  pixel a pixel como foram desenhados, sem nenhuma aproximação.

  ------------------------------------------------------------------
  O QUE ESTÁ GUARDADO AQUI
  ------------------------------------------------------------------
  Só o canal de TRANSPARÊNCIA de cada desenho, um byte por pixel, em
  hexadecimal. A cor não está no arquivo: ela é aplicada na hora, a
  partir da cor do tema — o mesmo desenho serve para qualquer cor.

  O LADO É 16, e não maior, porque estes convivem com os ícones
  desenhados à mão ao lado (play, stop, prev, next, CC, alerta), que
  ocupam de 12 a 16px. A primeira versão usou 22px e os dois ficaram
  visivelmente mais gordos que o resto da barra.

  Para trocar um desenho, gere a máscara a partir do PNG novo em vez de
  mexer nos números.
------------------------------------------------------------------------]]

local Glyphs = {}

local LADO = 16   -- o desenho ocupa 16px dentro do botão de 30px

--- Converte a máscara em hexadecimal para bytes de verdade.
local function alfa(hex)
  hex = hex:gsub('%s', '')
  local out = {}
  for i = 1, #hex, 2 do
    out[#out + 1] = string.char(tonumber(hex:sub(i, i + 1), 16))
  end
  return table.concat(out)
end

-- Seta em círculo: "recomeçar tudo", que é o que o Release faz.
Glyphs.release = { lado = LADO, alfa = alfa([[
  00000000050017d8500000000000000000000101000a60fffd81030304000000
  000101006fdcfffdfaffae0000000000000304a9fffffffaffeb590e45010100
  00008effffb164ffc22600a2ff8a00000036fdff9f00015c0300028cfffc3600
  00a0ffdd080202000003010addff9f0000daff86000400040100040087feda00
  00efff5f010400000000040160ffee0000e8ff6b01040000000004016bffe800
  00c4feaf0005000000000500affec300006ffff93f00040404050040f9ff6f00
  000ddaffe7450000000044e7ffda0d0000003bf9fffdb47c7cb4fdfff93b0000
  00020040d9ffffffffffffd94100030000000300127ac8e9e9c87a1200030000
]]) }

-- Engrenagem: as configurações.
Glyphs.gear = { lado = LADO, alfa = alfa([[
  00010000000091f3f3910000000001000100026a2c0ae7ffffe70a2c6a030001
  020aaefff2e0fffdfdffe1f2ffaf0a02006efff7fffffbfffffbfffff7ff6e00
  032debfefdfefff8f8fffefdfeeb2d03000ae0fffcfa751f1f77fbfcffe00a00
  94e4fffcff760000000078fffcffe493fdfffdfff71a030303031af7fffdfffc
  fdfffdfff71a030303031af7fffdfffc93e4fffcff770000000077fffcffe493
  000ae0fffcfb781f1f77fbfcffe00a00032debfefdfefff8f8fffefdfeeb2d03
  006efff7fffffbfffffbfffff7ff6e00020aaefff2e0fffdfdffe1f2ffaf0a02
  0100026a2c09e7ffffe70b2c6a03000100010000000091f3f391000000000100
]]) }

-- ------------------------------------------------- ícones do transporte
--
-- GERADOS por tools/gen_glyphs.lua a partir de desenhos VETORIAIS, com
-- 4x4 amostras por pixel. Não edite os números à mão: mexa nas formas do
-- gerador e rode-o de novo.
--
-- Estes eram desenhados com primitivas do ImGui e saíam serrilhados —
-- o play, o desfazer, o refazer e a próxima região eram os piores,
-- justamente os de ponta aguda ou feitos de linha mais triângulo
-- emendados. Como imagem, a borda é calculada uma vez, aqui, com
-- superamostragem, em vez de depender da franja de 0,5px que o ImGui
-- monta por primitiva.
--
-- TAMANHO 22, o mesmo em que são desenhados: 1 pixel da máscara para 1
-- pixel da tela. Qualquer ampliação embaça, e foi o que aconteceu quando
-- o release e a engrenagem (16px, desenhados pelo usuário) foram
-- esticados para 20 só para casar de tamanho.

-- GERADO por tools/gen_glyphs.lua. Não edite à mão.
-- Lado 22, 4x4 amostras por pixel.

Glyphs.play = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  0000000000af80000000000000000000000000000000
  0000000000ffffcf4000000000000000000000000000
  0000000000ffffffff9f100000000000000000000000
  0000000000ffffffffffef6000000000000000000000
  0000000000ffffffffffffffbf300000000000000000
  0000000000ffffffffffffffffff8010000000000000
  0000000000ffffffffffffffffffffdf400000000000
  0000000000ffffffffffffffffffffffff9f00000000
  0000000000ffffffffffffffffffffffff9f00000000
  0000000000ffffffffffffffffffffdf400000000000
  0000000000ffffffffffffffffff8010000000000000
  0000000000ffffffffffffffbf300000000000000000
  0000000000ffffffffffef6000000000000000000000
  0000000000ffffffff9f100000000000000000000000
  0000000000ffffcf4000000000000000000000000000
  0000000000af80000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.pause = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000006080806000000000608080600000000000
  0000000060ffffffff60000060ffffffff6000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000080ffffffff80000080ffffffff8000000000
  0000000060ffffffff60000060ffffffff6000000000
  00000000006080806000000000608080600000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.stop = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000208080808080808080808080802000000000
  00000020efffffffffffffffffffffffffef20000000
  00000080ffffffffffffffffffffffffffff80000000
  00000080ffffffffffffffffffffffffffff80000000
  00000080ffffffffffffffffffffffffffff80000000
  00000080ffffffffffffffffffffffffffff80000000
  00000080ffffffffffffffffffffffffffff80000000
  00000080ffffffffffffffffffffffffffff80000000
  00000080ffffffffffffffffffffffffffff80000000
  00000080ffffffffffffffffffffffffffff80000000
  00000080ffffffffffffffffffffffffffff80000000
  00000080ffffffffffffffffffffffffffff80000000
  00000080ffffffffffffffffffffffffffff80000000
  00000080ffffffffffffffffffffffffffff80000000
  00000020efffffffffffffffffffffffffef20000000
  00000000208080808080808080808080802000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.rec = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000003070808070300000000000000000
  00000000000030bfffffffffffffbf30000000000000
  000000000030efffffffffffffffffef300000000000
  0000000030efffffffffffffffffffffef3000000000
  00000000bfffffffffffffffffffffffffbf00000000
  00000030ffffffffffffffffffffffffffff30000000
  00000070ffffffffffffffffffffffffffff70000000
  00000080ffffffffffffffffffffffffffff80000000
  00000080ffffffffffffffffffffffffffff80000000
  00000070ffffffffffffffffffffffffffff70000000
  00000030ffffffffffffffffffffffffffff30000000
  00000000bfffffffffffffffffffffffffbf00000000
  0000000030efffffffffffffffffffffef3000000000
  000000000030efffffffffffffffffef300000000000
  00000000000030bfffffffffffffbf30000000000000
  00000000000000003070808070300000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.inicio = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000080bfaf00000000000000000000000000000000
  000000bfffff000000000000000000108f5000000000
  000000bfffff000000000000000040dfff8000000000
  000000bfffff000000000000008fffffff8000000000
  000000bfffff000000000030cfffffffff8000000000
  000000bfffff0000000070ffffffffffff8000000000
  000000bfffff000020bfffffffffffffff8000000000
  000000bfffff0030efffffffffffffffff8000000000
  000000bfffff0030efffffffffffffffff8000000000
  000000bfffff000020bfffffffffffffff8000000000
  000000bfffff0000000070ffffffffffff8000000000
  000000bfffff000000000030cfffffffff8000000000
  000000bfffff0000000000000080ffffff8000000000
  000000bfffff000000000000000040dfff8000000000
  000000bfffff000000000000000000108f5000000000
  00000080bfaf00000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.prev = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000080bfbf40000000000000000000001020000000
  000000bfffff8000000000000000000040dfbf000000
  000000bfffff8000000000000000108fffffbf000000
  000000bfffff8000000000000040dfffffffbf000000
  000000bfffff8000000000108fffffffffffbf000000
  000000bfffff8000000040dfffffffffffffbf000000
  000000bfffff8000108fffffffffffffffffbf000000
  000000bfffff8020cfffffffffffffffffffbf000000
  000000bfffff8020cfffffffffffffffffffbf000000
  000000bfffff8000108fffffffffffffffffbf000000
  000000bfffff8000000040dfffffffffffffbf000000
  000000bfffff8000000000108fffffffffffbf000000
  000000bfffff8000000000000040dfffffffbf000000
  000000bfffff8000000000000000108fffffbf000000
  000000bfffff8000000000000000000040dfbf000000
  00000080bfbf40000000000000000000001020000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.next = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000020100000000000000000000040bfbf80000000
  000000bfdf4000000000000000000080ffffbf000000
  000000bfffff8f100000000000000080ffffbf000000
  000000bfffffffdf4000000000000080ffffbf000000
  000000bfffffffffff8f100000000080ffffbf000000
  000000bfffffffffffffdf4000000080ffffbf000000
  000000bfffffffffffffffff8f100080ffffbf000000
  000000bfffffffffffffffffffcf2080ffffbf000000
  000000bfffffffffffffffffffcf2080ffffbf000000
  000000bfffffffffffffffff8f100080ffffbf000000
  000000bfffffffffffffdf4000000080ffffbf000000
  000000bfffffffffff8f100000000080ffffbf000000
  000000bfffffffdf4000000000000080ffffbf000000
  000000bfffff8f100000000000000080ffffbf000000
  000000bfdf4000000000000000000080ffffbf000000
  00000020100000000000000000000040bfbf80000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.lupa = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  0000000000001070bfbfbf8020000000000000000000
  000000000050efffffffffffff800000000000000000
  0000000050ffff8020001060efff8000000000000000
  00000010efff30000000000020efff40000000000000
  00000070ff800000000000000050ff9f000000000000
  000000bfff200000000000000000efef000000000000
  000000bfff000000000000000000bfff000000000000
  000000bfff100000000000000000dfef000000000000
  00000080ff600000000000000040ffaf000000000000
  00000020ffef20000000000010cfff50000000000000
  0000000080ffef5000000040cfffffcf100000000000
  000000000080ffffefbfdfffffbfffffcf1000000000
  000000000000409fefffefaf400060ffffcf10000000
  00000000000000000000000000000060ffffcf000000
  0000000000000000000000000000000060ff8f000000
  00000000000000000000000000000000001000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.undo = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000001050808050100000000000000000
  000000000000108fffffffffffff8f10000000000000
  000000000010cfffffffffffffffffcf100000000000
  0000000000bfffffaf20000020afffffbf0000000000
  0000000060ffff8000000000000080ffff6000000000
  00000000afffdf0000000000000000dfffaf00000000
  009fbfbfefffdf9f0000000000000080ffef00000000
  0080ffffffffff800000000000000040808000000000
  0010efffffffef100000000000000000000000000000
  000080ffffff80000000000000000000000000000000
  000010efffef10000000000000000000000000000000
  00000080ff8000000000000000000000000000000000
  00000010bf1000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.redo = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000001050808050100000000000000000
  000000000000108fffffffffffff8f10000000000000
  000000000010cfffffffffffffffffcf100000000000
  0000000000bfffffaf20000020afffffbf0000000000
  0000000060ffff8000000000000080ffff6000000000
  00000000afffdf0000000000000000dfffaf00000000
  00000000efff80000000000000009fdfffefbfbf9f00
  000000008080400000000000000080ffffffffff8000
  000000000000000000000000000010efffffffef1000
  00000000000000000000000000000080ffffff800000
  00000000000000000000000000000010efffef100000
  0000000000000000000000000000000080ff80000000
  0000000000000000000000000000000010bf10000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.loop = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  0000000000409fbfbfbfbfbfbfbfbf9f400000000000
  000000009fffffffffffffffffffffffff9f00000000
  0000008fffffffffffffffffffffffffffff8f000000
  000020ffffffffffffffffffffffffffffffff200000
  000080ffffffcf2000000000000020cfffffff800000
  000080ffffff50000000000000000050ffffff800000
  000080ffffff50000000000000000050ffffff800000
  000080ffffffcf2000000000000020cfffffff800000
  000020ffffffffffffffffffffffffffffffff200000
  0000008fffffffffffffffffffffffffffff8f000000
  000000009fffffffffffffffffffffffff9f00000000
  0000000000409fbfbfbfbfbfbfbfbf9f400000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.preparar = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000060808080808080808080808080808060000000
  000080ffffffffffffffffffffffffffffffff800000
  0000bfff7040404040404040404040404070ffbf0000
  0000bfff0010708040000000000000000000ffbf0000
  0000bfff0080ffffff000000000000000000ffbf0000
  0000bfff0080ffffff000000000000000000ffbf0000
  0000bfff0080ffffff000000000000000000ffbf0000
  0000bfff0080ffffff000000000000000000ffbf0000
  0000bfff0010708040000000000000000000ffbf0000
  0000bfff7040404040404040404040404070ffbf0000
  000080ffffffffffffffffffffffffffffffff800000
  00000060808080808080808080808080808060000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.cc = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  0000000070ef00000000afaf00000000ef7000000000
  0000000080ff00000000bfbf00000000ff8000000000
  0000000080ff00000000bfbf00000000ff8000000000
  0000000080ff000030efffffef300000ff8000000000
  0000000080ff000080ffffffff800000ff8000000000
  0000000080ff000030efffffef300000ff8000000000
  0000000080ff00000000bfbf00000000ff8000000000
  0000000080ff00000000bfbf00000000ff8000000000
  0000000080ff00000000bfbf00000000ff8000000000
  000010dfffffff600000bfbf00000000ff8000000000
  000060ffffffffbf0000bfbf00000000ff8000000000
  000010dfffffff600000bfbf000060ffffffdf100000
  0000000080ff00000000bfbf0000bfffffffff600000
  0000000080ff00000000bfbf000060ffffffdf100000
  0000000080ff00000000bfbf00000000ff8000000000
  0000000070ef00000000afaf00000000ef7000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.alerta = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  000000000000000000008f8f00000000000000000000
  00000000000000000050ffff50000000000000000000
  000000000000000000dfffffdf000000000000000000
  000000000000000080ffffffff800000000000000000
  0000000000000010efffffffffef1000000000000000
  000000000000009fffff3030ffff9f00000000000000
  00000000000020ffffff0000ffffff20000000000000
  000000000000bfffffff0000ffffffbf000000000000
  000000000040ffffffff0000ffffffff400000000000
  0000000000dfffffffff0000ffffffffdf0000000000
  0000000070ffffffffff3030ffffffffff7000000000
  00000010efffffffffffffffffffffffffef10000000
  0000008fffffffffffff7070ffffffffffff8f000000
  000020ffffffffffffff1010ffffffffffffff200000
  0000bfffffffffffffffdfdfffffffffffffffbf0000
  0000ffffffffffffffffffffffffffffffffffff0000
  00004080808080808080808080808080808080400000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.faixas = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000050808080808080808080808010000000000000
  000000ffffffffffffffffffffffff70000000000000
  000000ffffffffffffffffffffffff70000000000000
  00000050808080808080808080808010000000000000
  00000000000000000000000000000000000000000000
  00000000000010808080808080808080808050000000
  00000000000070ffffffffffffffffffffffff000000
  00000000000070ffffffffffffffffffffffff000000
  00000000000010808080808080808080808050000000
  00000000000000000000000000000000000000000000
  00000050808080808080803000000000000000000000
  000000ffffffffffffffffbf00000000000000000000
  000000ffffffffffffffffbf00000000000000000000
  00000050808080808080803000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.lixeira = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  000000000000000060ffffffff600000000000000000
  000000000000000080ffffffff800000000000000000
  00000030808080808fffffffff8f8080808030000000
  00000080ffffffffffffffffffffffffffff80000000
  00000010409fffffffffffffffffffff9f4010000000
  0000000000bfffffffffffffffffffffbf0000000000
  0000000000bfffff9fbfffffbf9fffffbf0000000000
  0000000000bfffff4080ffff8040ffffbf0000000000
  0000000000bfffff4080ffff8040ffffbf0000000000
  0000000000bfffff4080ffff8040ffffbf0000000000
  0000000000bfffff4080ffff8040ffffbf0000000000
  0000000000bfffff4080ffff8040ffffbf0000000000
  0000000000bfffff4080ffff8040ffffbf0000000000
  0000000000bfffff4080ffff8040ffffbf0000000000
  0000000000bfffffafcfffffcfafffffbf0000000000
  0000000000bfffffffffffffffffffffbf0000000000
  00000000003080808080808080808080300000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

Glyphs.juntar = { lado = 22, alfa = alfa([[
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  0000cfffffffffff400000000040ffffffffffcf0000
  0000ffffffffffff800000000080ffffffffffff0000
  0000ffffffffffff9f808080809fffffffffffff0000
  0000ffffffffffff9f808080809fffffffffffff0000
  0000ffffffffffff800000000080ffffffffffff0000
  0000cfffffffffff400000000040ffffffffffcf0000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
  00000000000000000000000000000000000000000000
]]) }

return Glyphs
]=], "@ui/glyphs.lua"))(...)
end

-- ============================ ui.waveform
package.preload["ui.waveform"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / ui/waveform.lua

  Lê os picos de áudio da track da música, para desenhar a forma de onda
  dentro da janela do LumiBridge.

  POR QUE EXISTE
    Achar um trecho específico da música olhando só para uma régua de
    tempo é adivinhação. Vendo a forma de onda, o refrão, a virada e o
    silêncio ficam visíveis, e clicar leva direto ao ponto.

  COMO OS PICOS SÃO OBTIDOS
    O REAPER expõe PCM_Source_GetPeaks, que devolve, para cada faixa de
    tempo, o valor máximo e o mínimo das amostras. É o mesmo dado que
    ele usa para desenhar a onda na própria timeline — não estamos
    decodificando áudio, só lendo o resumo que já existe.

    A leitura é CARA, então é feita uma vez por região e guardada. O
    desenho a cada quadro usa o vetor já pronto.

  TOLERÂNCIA A FALHA
    Se a API não estiver disponível, se a track não existir ou se o item
    ainda não tiver picos calculados, a função devolve nil e a interface
    desenha só a régua de tempo. Nada aqui pode derrubar a janela.
------------------------------------------------------------------------]]

local Waveform = {}

Waveform.backend = nil          -- injetável nos testes
--- Track onde vive a música. Escolhida pelo usuário nas Configurações;
--  'VS' é só o palpite inicial, não uma imposição.
Waveform.TRACK_NAME = 'VS'

local function api()
  return Waveform.backend or reaper
end

-- Cache: uma leitura por região.
local cache = { key = nil, peaks = nil, from = 0, to = 0 }

function Waveform.reset()
  cache = { key = nil, peaks = nil, from = 0, to = 0 }
end

--- Lista as tracks que têm áudio, para o usuário escolher.
--  Uma track de MIDI ou vazia não tem forma de onda a mostrar.
function Waveform.audioTracks()
  local r = api()
  local out = {}
  if not r.CountTracks then return out end

  for i = 0, r.CountTracks(0) - 1 do
    local track = r.GetTrack(0, i)
    local _, nome = r.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
    nome = (nome ~= '' and nome) or ('Track ' .. (i + 1))

    local temAudio = false
    for j = 0, r.CountTrackMediaItems(track) - 1 do
      local take = r.GetActiveTake(r.GetTrackMediaItem(track, j))
      if take and not (r.TakeIsMIDI and r.TakeIsMIDI(take)) then
        temAudio = true
        break
      end
    end

    if temAudio then
      out[#out + 1] = { index = i, name = nome }
    end
  end

  return out
end

--- Escolhe a track da forma de onda e descarta o cache.
function Waveform.setTrack(nome, indice)
  Waveform.TRACK_NAME = nome or ''
  Waveform.TRACK_INDEX = indice
  Waveform.reset()
end

--- Item de áudio da track da música que cobre um intervalo.
--- Item de áudio de uma track que cubra o intervalo.
local function itemNaTrack(track, startTime, endTime)
  local r = api()
  for j = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, j)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
    if pos < endTime and pos + len > startTime then
      local take = r.GetActiveTake(item)
      -- Só áudio: um item MIDI não tem forma de onda.
      if take and not (r.TakeIsMIDI and r.TakeIsMIDI(take)) then
        return item, pos, len
      end
    end
  end
  return nil
end

--- Acha o item de áudio a desenhar.
--
--  Com uma track escolhida, usa só ela. Sem escolha, PROCURA sozinha a
--  primeira track com áudio no trecho — exigir configuração para algo
--  que dá para descobrir é atrito à toa.
local function findItem(startTime, endTime)
  local r = api()
  if not r.CountTracks then return nil end

  local alvo = Waveform.TRACK_NAME:upper()

  if alvo ~= '' then
    for i = 0, r.CountTracks(0) - 1 do
      local track = r.GetTrack(0, i)
      local _, nome = r.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
      if (nome or ''):upper() == alvo then
        return itemNaTrack(track, startTime, endTime)
      end
    end
    return nil     -- a track escolhida não existe mais
  end

  for i = 0, r.CountTracks(0) - 1 do
    local track = r.GetTrack(0, i)
    local item, pos, len = itemNaTrack(track, startTime, endTime)
    if item then return item, pos, len end
  end
  return nil
end

--- A track tem algum item de áudio?
function Waveform.hasAudio(indice)
  local r = api()
  if not r.GetTrack or not r.CountTrackMediaItems then return false end
  local track = r.GetTrack(0, indice)
  if not track then return false end
  for j = 0, r.CountTrackMediaItems(track) - 1 do
    local item = r.GetTrackMediaItem(track, j)
    local take = item and r.GetActiveTake(item)
    if take and r.TakeIsMIDI and not r.TakeIsMIDI(take) then return true end
  end
  return false
end

--- Lê os picos de um intervalo de tempo.
--
--  @param buckets quantas colunas queremos (largura em pixels)
--  @return table de { min, max } normalizados em -1..1, ou nil
--- Quantas colunas são lidas do áudio, independentemente da largura.
--
--  A leitura dos picos é CARA: varre o arquivo inteiro do trecho. Antes
--  a quantidade vinha da largura da janela em pixels, e como o zoom
--  automático mexe na largura, a chave do cache mudava quase todo
--  quadro — a leitura era refeita sessenta vezes por segundo.
--
--  Com um número fixo, a leitura acontece UMA vez por música e o desenho
--  reamostra o que já está em memória.
Waveform.RESOLUTION = 1024

function Waveform.read(startTime, endTime, buckets)
  local r = api()
  local _ = buckets
  buckets = Waveform.RESOLUTION

  -- A chave não inclui a largura: só o trecho de música.
  local key = ('%.3f_%.3f'):format(startTime, endTime)
  if cache.key == key then return cache.peaks end

  -- TRAVA DE TEMPO. Ler os picos varre o arquivo de áudio e pode custar
  -- mais de cem milissegundos. Se algo fizer a chave mudar em sequência,
  -- sem esta trava a interface cai para poucos quadros por segundo — e a
  -- essa altura os cliques do mouse se perdem entre quadros.
  local agora = (r.time_precise and r.time_precise()) or 0
  if agora > 0 and agora < (cache.proxima or 0) then
    return cache.peaks
  end
  cache.proxima = agora + 0.5

  -- GUARDA TAMBÉM O FRACASSO.
  --
  -- Antes, quando não havia forma de onda a mostrar, a função saía sem
  -- gravar nada no cache — e varria TODAS as tracks e itens do projeto
  -- de novo no quadro seguinte. Num repertório com centenas de músicas
  -- isso derruba a taxa de quadros para dois ou três por segundo, e a
  -- essa altura os cliques do mouse começam a se perder entre quadros.
  local function semOnda()
    cache = { key = key, peaks = nil }
    return nil
  end

  if not r.PCM_Source_GetPeaks or not r.new_array then return semOnda() end

  local item, itemPos = findItem(startTime, endTime)
  if not item then return semOnda() end

  local take = r.GetActiveTake(item)
  if not take or (r.TakeIsMIDI and r.TakeIsMIDI(take)) then return semOnda() end

  local src = r.GetMediaItemTake_Source(take)
  if not src then return semOnda() end

  local duration = endTime - startTime
  if duration <= 0 then return semOnda() end

  -- Posição DENTRO da mídia: o item pode começar depois do arquivo e ter
  -- deslocamento de início. Ignorar isso desalinharia a onda da música.
  local offset = 0
  if r.GetMediaItemTakeInfo_Value then
    offset = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS') or 0
  end
  local srcStart = offset + (startTime - itemPos)

  local peakrate = buckets / duration
  local channels = 1

  -- O buffer recebe, por bucket: máximo, mínimo e um extra.
  local buf = r.new_array(buckets * channels * 3)
  buf.clear()

  local ok, got = pcall(r.PCM_Source_GetPeaks, src, peakrate, srcStart,
                        channels, buckets, 0, buf)
  if not ok or not got or got <= 0 then return semOnda() end

  local peaks = {}
  for i = 1, buckets do
    local maxV = buf[i] or 0
    local minV = buf[buckets + i] or 0
    peaks[i] = { min = minV, max = maxV }
  end

  cache = { key = key, peaks = peaks, from = startTime, to = endTime }
  return peaks
end

--- Há forma de onda disponível para este trecho?
function Waveform.available(startTime, endTime)
  return findItem(startTime, endTime) ~= nil
end

return Waveform
]=], "@ui/waveform.lua"))(...)
end

-- ============================ ui.renderer
package.preload["ui.renderer"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / ui/renderer.lua

  Desenha um Layout do Modelo na tela.

  REGRA DE ARQUITETURA:
    Este módulo conhece o Modelo e o ImGui. Não conhece o .form.
    Ele nunca vê palavras como "extraFunctionIndex" ou "TFreeFormShape".
    Recebe elementos já resolvidos e apenas os desenha.

  Estratégia de desenho:
    Tudo é desenhado na DrawList em coordenadas absolutas, exatamente
    como o .form descreve, multiplicado pelo zoom. Os cliques são
    capturados por InvisibleButton posicionado sobre cada controle.

    Por que não usar os widgets de botão do ImGui: precisamos de
    controle total sobre cor, borda e posição do texto para reproduzir
    a aparência do Lumikit. Widget nativo traria o estilo do ImGui junto.

  MILESTONE 1: ícones ainda não são desenhados. Eles já estão no Modelo
  (bitmap 32x32 em paleta indexada), prontos para a etapa que os
  renderizar, sem retrabalho no parser.
------------------------------------------------------------------------]]

local here  = (...):match('^(.*)%.[^%.]*$') or ''
local Theme     = require(here .. '.theme')
local IconCache = require(here .. '.icon_cache')
local Model     = require('core.model')
local Icons     = require('core.icons')

local Renderer = {}

-- Constantes visuais. Calibradas contra a captura de tela do Lumikit;
-- ficam aqui, isoladas, para facilitar o ajuste fino numa etapa futura.
local CAPTION_SIZE   = 9     -- fonte do nome dentro dos botões
local CAPTION_PAD    = 4     -- respiro do topo do botão até o texto
local CAPTION_BAND   = 16    -- altura reservada ao texto, acima do ícone
local ROUNDING       = 3
local BORDER_LIGHTEN = 0.16
local BORDER_DARKEN  = -0.28

-- Empurra a fonte usando a assinatura correta para a versão detectada.
--
-- IMPORTANTE: nada de tentativa-e-erro aqui. Chamar uma função da API do
-- REAPER com a contagem errada de argumentos abre o diálogo "ReaScript
-- Error" MESMO quando o erro é capturado por pcall. Sondar a assinatura
-- errando de propósito, portanto, não funciona.
--
-- A assinatura decorre da geração detectada em Theme.createFonts:
--   'scalable' (0.10)  ->  PushFont(ctx, font, size)
--   'ladder'   (<=0.9) ->  PushFont(ctx, font)
local function pushFont(ImGui, ctx, fonts, font, size)
  if fonts.mode == 'scalable' then
    ImGui.PushFont(ctx, font, size)
  else
    ImGui.PushFont(ctx, font)
  end
end

-- CACHE DE MEDIDAS DE TEXTO.
--
-- Cada chamada ao ReaImGui cruza a fronteira entre Lua e o REAPER, e é
-- esse cruzamento que custa caro — não a conta em si. Com 140 textos na
-- tela, medir todos a cada quadro eram 140 travessias por quadro, e o
-- mesmo texto na mesma fonte mede sempre igual.
--
-- Limpo quando a fonte ou o zoom mudam (ver Renderer.resetMetrics).
local textSizes = {}

local function measure(ImGui, ctx, text, chave)
  local k = chave .. '\0' .. text
  local m = textSizes[k]
  if m then return m[1], m[2] end

  local tw, th = ImGui.CalcTextSize(ctx, text)
  textSizes[k] = { tw, th }
  return tw, th
end

--- Esquece as medidas guardadas. Chamado quando o zoom muda.
function Renderer.resetMetrics()
  textSizes = {}
end

-- Fonte atualmente empilhada, para não empilhar a mesma de novo.
local fontAtual = nil
local lastZoom = nil

--- Desenha texto centralizado numa caixa.
local function textInBox(ImGui, ctx, dl, fonts, size, bx, by, bw, bh, col, text, valign)
  if not text or text == '' then return end
  local font, pushSize = Theme.pickFont(fonts, size)
  if not font then return end

  -- Só troca a fonte quando ela MUDA. Antes eram um Push e um Pop por
  -- texto — duzentas e oitenta travessias por quadro para, na maioria
  -- das vezes, empilhar a mesma fonte que já estava lá.
  local chave = tostring(font) .. '_' .. tostring(pushSize)
  if fontAtual ~= chave then
    if fontAtual then ImGui.PopFont(ctx) end
    pushFont(ImGui, ctx, fonts, font, pushSize)
    fontAtual = chave
  end

  local tw, th = measure(ImGui, ctx, text, chave)
  local tx = bx + (bw - tw) * 0.5
  local ty
  if valign == 'top' then
    ty = by
  else
    ty = by + (bh - th) * 0.5
  end
  ImGui.DrawList_AddText(dl, tx, ty, col, text)
end

-- --------------------------------------------------------- por tipo

local function drawShape(ImGui, dl, e, x, y, w, h, z)
  local fill   = Theme.rgba(e.color)
  local border = Theme.rgba(Model.shade(e.color, BORDER_LIGHTEN))
  ImGui.DrawList_AddRectFilled(dl, x, y, x + w, y + h, fill, ROUNDING * z)
  ImGui.DrawList_AddRect(dl, x, y, x + w, y + h, border, ROUNDING * z, 0, 1)
end

local function drawLabel(ImGui, ctx, dl, fonts, e, x, y, w, h, z)
  textInBox(ImGui, ctx, dl, fonts, e.fontSize * z, x, y, w, h,
            Theme.rgba(e.textColor), e.text, 'center')
end

local function drawButton(ImGui, ctx, dl, fonts, e, x, y, w, h, z, hovered, active, fkeyLabel)
  local noMidi = (not e.commands) or #e.commands == 0
  local base = e.orphan and Model.color(160, 48, 48) or e.color
  if hovered then base = Model.shade(base, Theme.HOVER_TINT) end

  ImGui.DrawList_AddRectFilled(dl, x, y, x + w, y + h, Theme.rgba(base), ROUNDING * z)

  -- Contorno, como no Lumikit.
  ImGui.DrawList_AddRect(dl, x, y, x + w, y + h,
    Theme.rgba(Model.shade(base, BORDER_DARKEN)), ROUNDING * z, 0, 1)

  -- Estado ligado: anel branco, como no Lumikit.
  if active then
    ImGui.DrawList_AddRect(dl, x, y, x + w, y + h,
      Theme.ACTIVE_RING, ROUNDING * z, 0, math.max(2, math.floor(2 * z)))
  end

  textInBox(ImGui, ctx, dl, fonts, CAPTION_SIZE * z,
            x, y + CAPTION_PAD * z, w, 0,
            Theme.rgba(e.textColor), e.text, 'top')

  -- Ícone, na mesma posição relativa em que o Lumikit o desenha.
  --
  -- Sem legenda, o ícone é centralizado nos DOIS eixos: a faixa
  -- reservada ao texto não faz sentido quando não há texto, e o botão
  -- ficava com o desenho deslocado para baixo.
  local img = IconCache.get(ImGui, ctx, e, active)
  if img then
    local faixa = (e.text and e.text ~= '') and CAPTION_BAND or 0
    local ix, iy = Icons.placement(e.w, e.h, faixa)
    local px, py = x + ix * z, y + iy * z
    local size = Icons.SIZE * z
    ImGui.DrawList_AddImage(dl, img, px, py, px + size, py + size)
  end

  -- Marca discreta no canto para controles sem mapeamento MIDI no .form.
  -- Eles não têm como acionar nada, e sem essa marca o usuário fica
  -- clicando num botão morto sem entender por quê.
  --
  -- INFERIOR ESQUERDO — canto oposto ao selo do atalho F1-F12 abaixo,
  -- para nunca sobrepor as duas.
  if noMidi then
    local m = 5 * z
    ImGui.DrawList_AddLine(dl, x + m * 2, y + h - m,
                           x + m, y + h - m * 2,
                           Theme.rgba(Model.shade(base, -0.5)), math.max(1, z))
  end

  -- Selo do atalho F1-F12 (LumiBridge, ver core/fkeys.lua), no canto
  -- INFERIOR DIREITO — canto oposto à marca de "sem MIDI" acima, para
  -- nunca sobrepor as duas.
  --
  -- V102 — pílula com contorno, escolhida pelo usuário entre 5 opções de
  -- prévia. A primeira versão (texto solto na cor do botão) era discreta
  -- demais; a segunda (chapinha sólida azul) ficava pesada e a cor fixa
  -- não combinava com todas as cores do .form. Aqui não existe cor fixa:
  -- a borda/texto é branco OU preto, escolhido pela luminância da PRÓPRIA
  -- cor do botão (mesmo cálculo de Model.luminance usado pro texto do
  -- botão), então sempre destaca sozinho, seja qual for a cor.
  if fkeyLabel and w >= 14 * z then
    local chipW = math.min(18 * z, w * 0.5)
    local chipH = (CAPTION_SIZE + 4) * z
    local cx = x + w - chipW - 2 * z
    local cy = y + h - chipH - 2 * z

    local fundoEscuro = Model.luminance(base) < 0.45
    local corSelo = fundoEscuro and Model.color(255, 255, 255) or Model.color(0, 0, 0)
    local borda = Theme.rgba(corSelo, 1.0)
    local veu = Theme.rgba(corSelo, fundoEscuro and 0.16 or 0.14)
    local raio = chipH * 0.5

    ImGui.DrawList_AddRectFilled(dl, cx, cy, cx + chipW, cy + chipH, veu, raio)
    ImGui.DrawList_AddRect(dl, cx, cy, cx + chipW, cy + chipH,
      borda, raio, 0, math.max(1, z))
    textInBox(ImGui, ctx, dl, fonts, (CAPTION_SIZE - 1) * z,
              cx, cy, chipW, chipH, borda, fkeyLabel, 'center')
  end
end

--- Geometria do trilho do fader.
--  Usada TANTO para desenhar QUANTO para converter a posição do mouse
--  em valor. Se as duas contas divergirem, o cursor não acompanha o
--  ponteiro — por isso existe uma função só.
function Renderer.faderTrack(y, h, z)
  local headerH = 16 * z
  return y + headerH + 6 * z, y + h - 18 * z, headerH
end

--- Fader vertical.
--  MILESTONE 1: a posição do cursor é estado local do LumiBridge, com
--  valor inicial de 100%. O valor real vive no Lumikit e não está no
--  .form; sincronizá-lo é assunto de uma etapa futura.
local function drawFader(ImGui, ctx, dl, fonts, e, x, y, w, h, z, hovered, value)
  local trackTop, trackBot, headerH = Renderer.faderTrack(y, h, z)
  local base = hovered and Model.shade(e.color, Theme.HOVER_TINT * 0.5) or e.color
  ImGui.DrawList_AddRectFilled(dl, x, y, x + w, y + h, Theme.rgba(base), ROUNDING * z)
  ImGui.DrawList_AddRect(dl, x, y, x + w, y + h,
    Theme.rgba(Model.shade(base, BORDER_DARKEN)), ROUNDING * z, 0, 1)

  textInBox(ImGui, ctx, dl, fonts, CAPTION_SIZE * z, x, y + 2 * z, w, headerH,
            Theme.rgba(e.textColor), e.text, 'top')

  local cx = x + w * 0.5
  ImGui.DrawList_AddLine(dl, cx, trackTop, cx, trackBot,
    Theme.rgba(Model.shade(base, -0.45)), math.max(1, 1 * z))

  -- Cursor.
  local pos = trackBot - (trackBot - trackTop) * value
  local handleW, handleH = w - 8 * z, 8 * z
  ImGui.DrawList_AddRectFilled(dl,
    cx - handleW * 0.5, pos - handleH * 0.5,
    cx + handleW * 0.5, pos + handleH * 0.5,
    0xFFFFFFFF, 1 * z)

  textInBox(ImGui, ctx, dl, fonts, CAPTION_SIZE * z,
            x, y + h - 16 * z, w, 14 * z,
            Theme.rgba(e.textColor), tostring(math.floor(value * 100 + 0.5)), 'top')
end

-- --------------------------------------------------------------- API

local INTERACTIVE = {
  [Model.KIND.BUTTON] = true,
  [Model.KIND.FADER]  = true,
  [Model.KIND.PAGE]   = true,
}

--- Desenha o layout inteiro.
--  @param state tabela mutável: { zoom, fonts, active = {}, faders = {} }
--  @return table  lista de eventos { element = e, kind = 'click' }
function Renderer.draw(ImGui, ctx, layout, state)
  -- A fonte é empilhada sob demanda durante o desenho e desempilhada no
  -- fim. Deixar uma empilhada corromperia os quadros seguintes.
  fontAtual = nil

  -- O zoom muda o tamanho do texto: as medidas guardadas não valem mais.
  if state.zoom ~= lastZoom then
    textSizes = {}
    lastZoom = state.zoom
  end
  local events = {}
  local z  = state.zoom
  local dl = ImGui.GetWindowDrawList(ctx)
  local ox, oy = ImGui.GetCursorScreenPos(ctx)

  -- SEM FUNDO PRÓPRIO AQUI.
  --
  -- Havia um retângulo cobrindo todo o layout, num cinza (0x1E1E1E) que
  -- não vem do .form nem da paleta do LumiBridge — era uma terceira cor,
  -- inventada, debaixo de tudo. Ela aparecia nos vãos entre os painéis
  -- do arquivo e dava ao conjunto um fundo que não é de ninguém.
  --
  -- O fundo do LumiBridge (Col_ChildBg) já está aí atrás. Não pintar é o
  -- que o deixa aparecer, e é o que foi pedido.
  --
  -- Os painéis do .form continuam com as cores DELE: o pedido era não
  -- usar a cor de fundo aplicada por baixo, não repintar o arquivo.

  -- ÁREA VISÍVEL, medida ANTES de qualquer widget.
  --
  -- A zona de clique abaixo ocupa o layout inteiro, e depois dela
  -- GetContentRegionAvail devolve o que SOBROU — quase nada. Medindo
  -- depois, a área ficava minúscula e quase todos os controles eram
  -- descartados: a tela mostrava só os painéis vazios.
  local visW, visH = ImGui.GetContentRegionAvail(ctx)
  local scrollX = ImGui.GetScrollX and ImGui.GetScrollX(ctx) or 0
  local scrollY = ImGui.GetScrollY and ImGui.GetScrollY(ctx) or 0
  local vx0 = ox + scrollX - 32
  local vy0 = oy + scrollY - 32
  local vx1 = vx0 + ((visW and visW > 0) and visW or 4000) + 64
  local vy1 = vy0 + ((visH and visH > 0) and visH or 4000) + 64

  for i = 1, #layout.elements do
    local e = layout.elements[i]
    if not e.hidden and not e.covered then
      local x, y = ox + e.x * z, oy + e.y * z
      local w, h = e.w * z, e.h * z

      -- DESCARTE POR ÁREA VISÍVEL: REMOVIDO.
      --
      -- A ideia era pular o que está fora da tela, e a economia era
      -- real. Mas depende de GetContentRegionAvail devolver a área do
      -- canvas, e com a janela acoplada o valor vinha de forma que
      -- descartava TODOS os controles: a tela mostrava os painéis
      -- vazios, sem botão nenhum.
      --
      -- Uma tela que não funciona não compensa quadros a mais. O ganho
      -- grande veio da zona de clique única, que continua valendo.
      local _ = vx0

      -- UM WIDGET POR CONTROLE.
      --
      -- Custa quatro chamadas por controle, e já tentei trocar isso por
      -- uma zona única com o acerto calculado em Lua. A conta de
      -- desempenho fechava, mas a tela quebrava: a zona única muda a
      -- ordem de desenho do ImGui e os painéis passavam a cobrir os
      -- botões.
      --
      -- Fica como está. Correção vale mais que velocidade, e o ganho
      -- real veio das outras mudanças: não desenhar o que está fora da
      -- tela, não reempilhar a fonte a cada texto e não reler o item
      -- MIDI a cada consulta do espelho.
      local hovered, clicked, rightClicked = false, false, false
      if INTERACTIVE[e.kind] and w >= 1 and h >= 1 then
        ImGui.SetCursorScreenPos(ctx, x, y)
        ImGui.InvisibleButton(ctx, ('##lb%d'):format(i), w, h)
        hovered = ImGui.IsItemHovered(ctx)
        clicked = ImGui.IsItemClicked(ctx)

        -- Clique direito, pra atribuir tecla F1-F12 (ver janela ao
        -- lado). NÃO passa flags extras pro InvisibleButton pra
        -- aceitar o botão direito: isso faria IsItemActive responder
        -- a ele também, e um botão momentâneo passaria a "segurar"
        -- (soltar nota MIDI) com o clique direito, o que não é o
        -- comportamento que se quer aqui. Em vez disso, só olha se
        -- o item está sob o mouse E se o botão direito foi clicado
        -- neste quadro — não interfere em nada mais.
        if hovered and ImGui.IsMouseClicked(ctx, 1) then rightClicked = true end
      end

      if e.kind == Model.KIND.SHAPE then
        drawShape(ImGui, dl, e, x, y, w, h, z)

      elseif e.kind == Model.KIND.LABEL then
        drawLabel(ImGui, ctx, dl, state.fonts, e, x, y, w, h, z)

      elseif e.kind == Model.KIND.FADER then
        local key = e.tag or i
        local Session = require('core.session')

        -- Arrasto contínuo: enquanto o botão do mouse estiver segurando
        -- este item, o valor acompanha o ponteiro. IsItemActive continua
        -- verdadeiro mesmo com o cursor fora do controle, então dá para
        -- arrastar para fora sem perder o fader.
        -- Roda do mouse com o cursor sobre o fader.
        if hovered then
          local wheel = ImGui.GetMouseWheel(ctx)
          if wheel and wheel ~= 0 then
            -- Shift dá o passo fino, como em qualquer controle de áudio.
            local fine = false
            if state.shiftDown ~= nil then fine = state.shiftDown end
            events[#events + 1] = {
              element = e, index = i, kind = 'wheel',
              notches = wheel, fine = fine,
            }
          end
        end

        if ImGui.IsItemActive(ctx) then
          local _, my = ImGui.GetMousePos(ctx)
          local trackTop, trackBot = Renderer.faderTrack(y, h, z)
          local span = trackBot - trackTop
          local value = 0.0
          if span > 0 then value = (trackBot - my) / span end
          if value < 0 then value = 0 elseif value > 1 then value = 1 end
          events[#events + 1] =
            { element = e, index = i, kind = 'fader', value = value }
        end

        drawFader(ImGui, ctx, dl, state.fonts, e, x, y, w, h, z,
                  hovered, Session.faderValue(state.session, e, key))

      else -- BUTTON e PAGE
        local key = e.tag or i
        local Session = require('core.session')
        local fkeyLabel = state.fkeyBadge and e.tag and state.fkeyBadge[e.tag]
        drawButton(ImGui, ctx, dl, state.fonts, e, x, y, w, h, z,
                   hovered, Session.isActive(state.session, e, key), fkeyLabel)
      end

      if hovered then state.hovered = e end
      -- Botões momentâneos precisam de borda de descida e de subida.
      -- Detectamos por conta própria comparando IsItemActive com o quadro
      -- anterior, em vez de usar IsItemActivated/IsItemDeactivated: são
      -- menos funções da API para dar errado entre versões do ReaImGui.
      if e.momentary and INTERACTIVE[e.kind] and w >= 1 and h >= 1 then
        local key = e.tag or i
        local holding = ImGui.IsItemActive(ctx)
        local was = state.holding[key] or false
        if holding and not was then
          events[#events + 1] = { element = e, index = i, kind = 'press' }
        elseif was and not holding then
          events[#events + 1] = { element = e, index = i, kind = 'release' }
        end
        state.holding[key] = holding
      elseif clicked and e.kind ~= Model.KIND.FADER then
        events[#events + 1] = { element = e, index = i, kind = 'click' }
      end

      -- Clique direito: independente de momentâneo ou não, e de FADER
      -- (arrastar com o botão direito não faz sentido aqui).
      if rightClicked and e.kind ~= Model.KIND.FADER then
        events[#events + 1] = { element = e, index = i, kind = 'rightclick' }
      end
    end
    ::proximo::
  end

  -- Reserva a área total para que a rolagem funcione.
  ImGui.SetCursorScreenPos(ctx, ox, oy)
  ImGui.Dummy(ctx, layout.contentWidth * z, layout.contentHeight * z)

  -- Desempilha a última fonte usada: o estado do ImGui tem de sair do
  -- quadro como entrou.
  if fontAtual then
    ImGui.PopFont(ctx)
    fontAtual = nil
  end

  return events
end

return Renderer
]=], "@ui/renderer.lua"))(...)
end

-- ============================ ui.window
package.preload["ui.window"] = function(...)
  return assert(load([=[
--[[----------------------------------------------------------------------
  LumiBridge / ui/window.lua

  Janela principal: barra de ferramentas, carregamento do arquivo e o
  laço de quadros.

  Este módulo é o único que fala com a API do REAPER na Milestone 1.
------------------------------------------------------------------------]]

local Compat     = require('ui.imgui_compat')
local Theme      = require('ui.theme')
local Renderer   = require('ui.renderer')
local FormParser = require('core.form_parser')
local Model      = require('core.model')
local Rules      = require('core.rules')
local Session    = require('core.session')
local Curve      = require('core.curve')
local IconCache  = require('ui.icon_cache')
local Glyphs     = require('ui.glyphs')
local MidiOut    = require('midi.output')
local Timeline   = require('midi.timeline')
local Transport  = require('midi.transport')
local CCLanes    = require('midi.cclanes')
local Waveform   = require('ui.waveform')
local Recorder   = require('core.recorder')
local Calibration= require('core.calibration')
local FKeys      = require('core.fkeys')
local FaderGroups = require('core.fadergroups')
local Lanes      = require('core.lanes')
local Version    = require('core.version')

local Window = {}

local EXT_SECTION  = 'LumiBridge'
local EXT_LASTFILE = 'last_form'
local EXT_MIDIPORT = 'midi_port_name'
local EXT_TRACK    = 'record_track_name'
-- Prefixo da chave dos atalhos F1-F12 no ExtState. Um jogo de atalhos
-- POR TELA: a chave completa é EXT_FKEYS_PREFIX .. layout.freeFormHash,
-- então trocar de .form troca o conjunto de F1-F12 automaticamente,
-- sem misturar os atalhos de uma tela na outra.
local EXT_FKEYS_PREFIX = 'fkeys_'
-- Mesma ideia do EXT_FKEYS_PREFIX, mas para os grupos de fader por tecla
-- numérica (1..9, 0): um jogo de grupos POR TELA.
local EXT_FADERGROUPS_PREFIX = 'fadergroups_'
-- Mesma ideia: qual controle é o Release All DESTA tela.
local EXT_RELEASE_PREFIX = 'release_'
-- E as cores escolhidas à mão para as faixas de programação.
local EXT_LANECOLOR_PREFIX = 'lanecolor_'
local EXT_OFFSET   = 'latency_offset'

local ImGui, ctx
local COND_FIRST_USE = 0
local state = {
  zoom    = 1.0,
  fonts   = nil,
  active  = {},   -- tag -> ligado/desligado (estado local, visual)
  holding = {},   -- tag -> botão do mouse segurando (momentâneos)
  faders  = {},   -- tag -> 0..1
  hovered = nil,
  fkeyBadge = {}, -- tag -> "F1".."F12", ver buildShortcuts
}

local layout      = nil
local loadError   = nil
local statusText  = 'Nenhum arquivo carregado.'
-- INTERRUPTORES DA INTERFACE, numa tabela só.
--
-- Eram quatro locais soltos, e este arquivo bateu de novo no teto de 200
-- locais por chunk do Lua — o mesmo teto que já obrigou a agrupar o
-- estado das faixas e o da janela. Estado relacionado agrupado gasta um
-- local só, e ainda lê melhor: são todos "o que está ligado na tela".
--
--   detalhes  geometria e comando MIDI do controle sob o cursor
--   zoom      o layout acompanha o tamanho da janela
--   atalhos   teclas do .form e as F1-F12
--   dicas     balões de ajuda ao passar o mouse. Ligadas, ensinam a
--             interface; ligadas o tempo todo, atrapalham quem já
--             aprendeu — a da lista de faixas cobre metade da área de
--             programação enquanto se trabalha nela.
local opcoes = {
  detalhes = false,
  zoom     = true,
  atalhos  = true,
  dicas    = true,
  -- O QUE APARECE NA BARRA DE TRANSPORTE.
  --
  -- A barra é o lugar mais disputado da janela: é onde os ícones somem
  -- pela borda quando a janela encolhe. Então o que não é de todo dia
  -- entra desligado, e quem usa liga.
  --
  --   regioes  os botões de região anterior e próxima
  --   relogio  a posição em minutos e segundos
  regioes = false,
  relogio = false,
  -- REPETIR A REGIÃO era um botão na barra; virou só ajuste. Ligado por
  -- padrão porque programar iluminação é repetir o mesmo trecho — é o
  -- estado em que se passa quase todo o tempo, e um botão para o estado
  -- normal é um botão que nunca se aperta.
  repetir = true,
  -- EM TORNO DE QUÊ O ZOOM APROXIMA.
  --
  --   false  o cursor de reprodução — o traço verde que anda com a
  --          música. Aproximar mantém debaixo do olho o ponto que está
  --          sendo ouvido, que é o que se quer ao ajustar o que acabou
  --          de tocar. É o padrão.
  --   true   o ponteiro do mouse, como num editor de áudio: o ponto
  --          apontado fica onde está e o resto se aproxima dele. Serve
  --          para mirar um trecho longe do cursor sem tirar o play do
  --          lugar.
  zoomNoMouse = false,
  -- ÍMÃ ENTRE AS NOTAS.
  --
  -- Dois controles clicados "praticamente juntos" ficam a poucos
  -- milissegundos um do outro, e acionar junto é o que se queria — mas
  -- acertar isso arrastando à mão, num pixel, é impossível. Com o ímã, a
  -- borda arrastada cola na borda mais próxima de QUALQUER outra linha
  -- quando chega perto: aproximar já basta.
  --
  -- Ligado por padrão: quem arrasta uma borda quase sempre quer casá-la
  -- com alguma coisa; quem quer o valor exato desliga, ou aproxima o
  -- zoom até a distância de encaixe virar menos que um quadro.
  ima = true,
}
local auditWarning = nil  -- aviso de atributo não reconhecido no .form
local devices     = {}   -- portas MIDI, relidas sob demanda
local session     = nil  -- estado vivo da interação (core/session.lua)
local fkeyMap        = {}   -- código F1-F12 -> tag; ver FKeys, por tela
local fkeyMenuElement = nil -- controle com o menu de clique direito aberto
local faderGroups    = {}   -- num ('1'..'9','0') -> {mode, tags}; por tela
-- Alvo compartilhado do grupo no modo "mesmo valor", enquanto a tecla
-- está segurada. Recomeça (a partir do valor atual dos faders) toda vez
-- que a tecla é solta e pressionada de novo — ver handleFaderGroups.
local groupSameTarget = {}  -- num -> 0..1
local groupWasHeld    = {}  -- num -> true/false no quadro anterior
-- Grupos com a tecla segurada NESTE quadro — preenchida por
-- handleFaderGroups, lida mais abaixo pra também propagar o ARRASTO de
-- um fader do grupo (não só a roda) aos demais membros.
local groupHeldNow    = {}
local dica               -- auxiliar de dicas; definido mais abaixo
local ajuste             -- linha "nome à esquerda, controle à direita"
                          -- das Configurações; definido mais abaixo, mas
                          -- drawMidiBar (mais acima no arquivo) precisa
                          -- chamar antes disso, daí a declaração adiantada
local aba                -- cabeçalho de aba; definido mais abaixo
local buildShortcuts     -- monta a lista de atalhos; definido mais abaixo,
                          -- mas a aba Atalhos das Configurações precisa
                          -- chamar antes disso, daí a declaração adiantada
local waveTracks = {}    -- tracks com áudio, para a forma de onda
local logAviso           -- última mensagem sobre o registro
local rotaAviso          -- resultado do preparo da track
local abaAtual = 'arquivo'  -- aba aberta (fica fora de `painel`:
                            -- é declarada bem antes dele)
local waveTrack = ''        -- track de onde vem a forma de onda
local regionPinned = false  -- o usuário já escolheu a música?
local buscaRegiao  = ''     -- filtro da lista de músicas
local regioesOrdenadas = {} -- mesma lista, em ordem alfabética
local grupoSelecionado = '1' -- grupo de fader escolhido na aba Grupos
local buscaFader   = ''     -- filtro da lista de faders daquele grupo
-- O ESTADO DO ENCAIXE AUTOMÁTICO, numa tabela só (teto de 200 locais).
--
--   w, h   tamanho da área na última vez que a escala foi calculada.
--          Zerar `w` é como o resto do arquivo pede um reencaixe.
--   mudou  quantas vezes a escala mudou de verdade. Aparece no
--          diagnóstico: se a tela parece pular, este número separa "o
--          layout está mudando de tamanho" de "está lento".
local encaixe = {
  w = 0, h = 0, mudou = 0,
  -- A REPARTIÇÃO DA BARRA: onde a linha começou, a folga entre os
  -- blocos e o vão que sobrou antes do último. Medidos num quadro e
  -- usados no seguinte — o ImGui é imediato, e ao desenhar a primeira
  -- folga ainda não se sabe quanto o resto vai ocupar. A largura dos
  -- botões não muda entre quadros, e um quadro de atraso a trinta por
  -- segundo ninguém vê.
  barraX0 = 0, respiro = nil, barraSobra = nil,
}


-- Quanto tempo sem nova leitura encerra um gesto de fader, em segundos.
-- Curto o bastante para não atrasar a gravação, longo o bastante para
-- não partir uma sequência de giros da roda em vários gestos.
local GESTO_TIMEOUT = 0.35

-- MEDIÇÃO DE DESEMPENHO.
--
-- Quando a interface fica lenta, cliques do mouse se perdem entre
-- quadros e o sintoma aparece como "o botão não enviou". Adivinhar qual
-- etapa está pesando custou rodadas; medir resolve em uma.
local perf = { barra = 0, onda = 0, canvas = 0, espelho = 0, total = 0 }
local perfCount = 0

local function cronometro()
  return reaper.time_precise and reaper.time_precise() or 0
end

-- O PIOR QUADRO de cada janela de três segundos, por trecho.
--
-- `atual` acumula a janela em curso; `ultimo` é a janela fechada, que é
-- a que se mostra — assim o número não fica variando enquanto se lê.
local pico = { atual = {}, ultimo = {}, ate = 0 }

-- GEOMETRIA DA JANELA, quadro a quadro.
--
-- "A janela inteira se mexe": a moldura mudando de tamanho ou de lugar
-- na tela do Windows, não o conteúdo. Nada aqui move a janela sem ser
-- pedido — arrastar a barra, maximizar, minimizar —, então ou uma dessas
-- está disparando sozinha, ou quem move é o ReaImGui. As duas respostas
-- levam a lugares diferentes, e adivinhar já custou duas correções que
-- não corrigiram nada.
--
-- `contadas` conta todas as mudanças; `ditas` limita quantas vão para o
-- registro, senão sessenta linhas por segundo afogam tudo o mais.
local geo = { x = nil, y = nil, w = nil, h = nil, contadas = 0, ditas = 0 }

local function medir(chave, t0)
  local dt = cronometro() - t0
  -- Média móvel: um pico isolado não deve dominar o diagnóstico.
  perf[chave] = (perf[chave] or 0) * 0.9 + dt * 0.1

  -- E O PICO, ao lado dela.
  --
  -- A média existe justamente para um quadro isolado não dominar o
  -- diagnóstico — e é por isso mesmo que ela ESCONDE uma pulada, que é
  -- um quadro isolado e nada mais. Trinta quadros de 8 ms e um de 200
  -- dão uma média de 14 ms: saudável no papel, e visível como um
  -- tranco. Os dois números juntos separam "está lento" de "engasga".
  if dt > (pico.atual[chave] or 0) then pico.atual[chave] = dt end
end
local faderMov = {}         -- leituras de cada fader em movimento
local meus = {}             -- controles que EU toquei nesta gravação

-- Até onde a automação de CC de cada fader já foi limpa/reescrita NESTA
-- gravação (chave: tag do fader -> QN). Um fader tocado durante o REC
-- fica seu até o STOP (não só até você soltar o mouse): cada vez que
-- você mexe nele de novo, a limpeza continua exatamente daqui, sem
-- deixar buraco nem reapagar o que já foi escrito. Zerado a cada
-- REC novo; consumido (com um ponto final na posição do stop) em
-- stopRecording().
local manualCursor = {}
local logText            -- registro como texto; definido mais abaixo
local drawAvisos         -- avisos da janela principal; definido abaixo

local recorder    = nil  -- estado da gravação (core/recorder.lua)
local recording   = false
local tracks      = {}
local latency     = 0.0  -- segundos a descontar do clique
local calib       = nil  -- calibração manual em andamento
local autoCal     = nil  -- observação dos cliques normais
local autoOn      = true -- sugerir offset a partir dos cliques?
-- ESTADO DO QUADRO A QUADRO: relógio, ritmo e o que o quadro anterior
-- viu. Numa tabela só pelo teto de 200 locais do Lua, que este arquivo
-- já estourou duas vezes (ver test_integridade).
local quadro = {
  recheckAt   = 0,     -- próximo instante de revalidação (segundos)
  ultimoEm    = nil,   -- instante do quadro anterior
  media       = 1/30,  -- intervalo médio entre quadros, medido
  tocava      = false, -- estado do play no quadro anterior
  ultimaQN    = nil,   -- última posição enquanto tocava, em semínimas
  regiaoAt    = 0,     -- próxima releitura da região
  preparada   = nil,   -- nome da região já preparada
}
-- O ESPELHO: acender na tela o que está gravado, conforme o cursor passa.
--
-- Numa tabela só pelo teto de 200 locais do Lua. Ver PROJECT_CONTEXT.md.
local espelho = {
  seguir    = true,  -- acender os botões conforme o play passa
  envia     = true,  -- e mandar o MIDI correspondente ao Lumikit
  ate       = 0,     -- próxima leitura do que está soando
  -- Última posição em que o espelho rodou PARADO. Serve para ele reagir
  -- a arrastar o cursor sem reescrever a tela a cada quadro.
  ultimaPos = nil,
  -- Controles que VOCÊ acendeu com o cursor parado, e não o espelho.
  -- É o que o REC usa para saber o que é intenção sua e o que é só o
  -- reflexo do que já está gravado naquele ponto.
  marcados  = {},
}

--- A track já entrega o que o espelho ia mandar?
--
--  DUAS FONTES, UMA NOTA. Quando a track tem saída de hardware para a
--  mesma porta que usamos, o REAPER toca cada nota da programação e o
--  espelho manda a mesma nota de novo. Os controles do Lumikit são
--  toggle — dois Note On acendem e apagam, e o botão fica como estava.
--
--  O sintoma é enganoso: os botões acendem na nossa tela (que é
--  desenhada do que está GRAVADO, não do MIDI que sai) e não acendem no
--  Lumikit nem no 3D. O mesmo arquivo tocado só pelo REAPER acende.
--
--  Na rota 'track' a duplicata é certa: nossas mensagens entram pelo
--  teclado virtual e saem pela mesma track que está tocando o item.
--
--  Método de `espelho` e não local do arquivo: o corpo deste módulo está
--  no teto de 200 locais do Lua.
function espelho.duplicaria()
  if not MidiOut.enabled then return false end
  local porta, mudo = Timeline.saidaDaTrack()
  if not porta or mudo then return false end
  if MidiOut.route == 'track' then return true end
  return porta == MidiOut.deviceIndex
end
-- PREPARO DE MÚSICA — o que o LumiBridge escreve sozinho ao começar uma
-- música do zero. Tudo opcional e tudo desligável: cada operador tem um
-- jeito de abrir a música, e o que é conveniência para um é intromissão
-- para outro.
--
-- `preparo.auto` é a chave geral, e vale só para o que acontece SOZINHO:
-- o preparo ao apertar REC numa região vazia e a abertura ao dar play.
-- O botão "Preparar" continua funcionando desligado — ele é um pedido
-- explícito, e recusar um pedido explícito por causa de uma preferência
-- de automação seria só confuso.
--
-- Numa tabela só, pela mesma razão de `faixas` e `maxi`: o teto de 200
-- locais por chunk do Lua, que este arquivo já estourou duas vezes.
local preparo = {
  auto    = true,   -- preparar/abrir sem ser pedido
  release = true,   -- Release All no primeiro tempo
  faders  = true,   -- pontos de CC no começo e no fim da música
  -- A POSIÇÃO DA TELA MANDA, e não um 100% fixo.
  --
  -- Era o contrário, e o resultado foi o relatado: os faders aparecem
  -- posicionados na tela ao preparar, a gravação começa em 100% assim
  -- mesmo, e nada explica a diferença. A tela mostrando uma coisa e a
  -- gravação fazendo outra é o pior tipo de surpresa.
  --
  -- Ninguém que queira 100% perde nada com isto: os faders NASCEM em
  -- 100%, então não mexer neles dá exatamente o mesmo resultado de
  -- antes. O interruptor continua existindo para quem quiser ignorar a
  -- tela de propósito.
  cem     = false,  -- 100% fixo, em vez da posição atual
}
local region      = nil  -- região em que se está trabalhando
-- CHROME DA JANELA — sempre por cima, arrasto da barra própria,
-- minimizar, restaurar e o pedido de fechar.
--
-- Numa tabela só pelo teto de 200 locais do Lua, que este arquivo
-- estourou duas vezes. Ver PROJECT_CONTEXT.md e a verificação de
-- folga em tests/test_integridade.lua.
local chrome = {
  minimizado = false,  -- encolhida na pastilha
  aoAlto     = true,   -- manter a janela acima do REAPER
  fechar     = false,  -- o X da barra própria foi clicado
  arrastando = false,  -- a barra de título está sendo arrastada
  offX = 0, offY = 0,  -- distância do mouse ao canto, no arrasto
  normalW = 1200, normalH = 800,  -- tamanho antes de minimizar
  pendW = nil, pendH = nil,       -- tamanho a aplicar no quadro seguinte
  restaurando = 0,     -- quadros de transição ao voltar da pastilha
  -- LICENÇA, aqui e não num local próprio.
  --
  -- Ela é do mesmo tipo que `minimizado`: decide se a janela mostra o
  -- programa ou outra coisa no lugar dele. E o corpo deste módulo está
  -- no teto de 200 locais do Lua — um local a mais aqui derruba o
  -- arquivo inteiro na carga, que é o pior lugar para descobrir isso.
  lic = { ativa = false, codigo = nil, digitada = '', erro = nil,
          aviso = nil },
}
-- MINIMIZADO: a janela encolhe até virar uma pastilha com o ícone, em
-- vez de sumir. NÃO é lembrado entre sessões, de propósito — abrir o
-- programa e encontrar só uma pastilha, sem lembrar por quê, seria
-- confuso.
-- FAIXAS DE PROGRAMAÇÃO — o que está gravado nesta música, por controle
-- do .form. Ver drawFaixas e core/lanes.lua.
--
-- NUMA TABELA SÓ, e não uma variável local por campo, porque o Lua tem
-- um TETO DE 200 LOCAIS por chunk e este arquivo chegou nele: a primeira
-- versão destas faixas não compilava mais, com um erro que fala do teto
-- e não do que fazer ("too many local variables"). Estado relacionado
-- agrupado gasta um local só — e lê melhor.
local faixas = {
  abertas = false,
  altura  = 150,    -- altura do corpo, em pixels
  inteira = false,  -- ocupando o lugar do painel do .form
  -- AO LADO do painel, em vez de embaixo dele.
  --
  -- Embaixo, o .form encolhe até caber na altura que sobra, e como ele é
  -- muito mais largo que alto (1440x752 no caso de uso real, quase 2:1)
  -- quem manda passa a ser a altura: sobra uma faixa em branco à direita
  -- e os botões ficam pequenos. Ao lado, o .form fica com a altura toda
  -- e é a largura da coluna que manda — e as faixas ganham a lista na
  -- vertical, que é onde elas sufocam (são mais de cem controles).
  --
  -- Qual dos dois serve depende do momento da programação, então é
  -- escolha de quem está olhando, não uma regra.
  lado    = false,
  largura = nil,    -- largura da coluna nesse modo (nil = 42% do espaço)
  todos   = false,  -- mostrar também controles sem nada gravado
  semCC   = false,  -- esconder as faixas de fader (botão da barra)
  -- Vista compartilhada com a forma de onda. nil = música inteira.
  vDe = nil, vAte = nil,
  escalaV = 1,       -- zoom vertical: multiplica a altura das linhas
  gutter  = nil,     -- largura da coluna de nomes (nil = padrão)
  rolagem = 0,
  -- Acionamentos pedidos pela coluna de nomes, para entrar na MESMA fila
  -- de eventos do .form (ver o laço de eventos em `frame`).
  acionar   = {},
  segurando = {},   -- quem está com o nome pressionado, por tag
  arrasteFader = nil, -- fader sendo puxado pelo nome { tag, x0, v0 }
  sobNome = nil,    -- linha sob o mouse na coluna de nomes
  seguirCursor = true, -- com zoom, a vista salta para acompanhar o play
  menuEl    = nil,  -- elemento do .form do menu de faixa aberto
  pedirTeclaF = nil,-- pedido de abrir o menu de tecla F no quadro seguinte
  linhas  = {},     -- resultado de Lanes.build, refeito 4x/s
  at      = 0,      -- próxima remontagem
  sel     = nil,    -- bloco selecionado { tag, pitch, t0 }
  arrastePonto = nil, -- arrasto de um ponto de automação em curso
  -- SELEÇÃO DE VÁRIOS PONTOS DE CC.
  --
  -- `laco` é o retângulo enquanto se arrasta; `selCC` é o resultado,
  -- guardado por tag e por INSTANTE — nunca por índice. O índice de um
  -- ponto muda a cada inserção e remoção, e a lista é remontada quatro
  -- vezes por segundo: uma seleção por índice apontaria para outros
  -- pontos meio segundo depois.
  laco  = nil,      -- { x0, y0, x1, y1 } em pixels de tela
  selCC = {},       -- [tag] = { [instante] = true }
  -- E O MESMO PARA AS NOTAS: [tag] = { [início do bloco] = true }.
  --
  -- Por POSIÇÃO, nunca por índice — a mesma regra do resto do arquivo.
  -- Apagar ou inserir uma nota renumera as seguintes, e uma seleção
  -- guardada por índice passaria a apontar para outras notas no quadro
  -- seguinte.
  selNotas = {},
  arraste = nil,    -- arrasto de borda em curso
}

-- Confirmação pendente, desenhada por nós no fim do quadro.
local confirmar   = nil
-- Folga em volta do painel do .form, em pixels de tela.
--
-- O conteúdo do arquivo termina no último pixel do último controle, e a
-- janela deixou de ter espaçamento próprio (ver Theme.push) — sem esta
-- folga os botões colam nas bordas direita e inferior.
-- MEDIDAS DO DESENHO, numa tabela só (o teto de 200 locais do Lua não
-- sobra para uma variável por número — ver test_integridade).
--
-- `botao` e `espaco` são CONSTANTES DE VERDADE, não números repetidos: o
-- botão da barra já foi 30 e virou 34, a conta que empurra o grupo da
-- direita para o canto continuou com 30, e o último botão passou a sair
-- pela borda — as Configurações apareciam cortadas. Número copiado é
-- número que vai divergir.
local M = {
  folga  = 8,    -- folga em volta do painel do .form, em pixels de tela
  botao  = 34,   -- lado de um botão da barra de transporte
  espaco = 7,    -- espaçamento entre itens (o mesmo do ItemSpacing)
  -- A FOLGA DA BARRA DE TRANSPORTE, dos DOIS lados e de um número só.
  --
  -- A da esquerda saía de um Dummy de 6px MAIS o espaçamento entre itens
  -- (7), dando 13; a da direita era um 8 escrito à mão noutro ponto do
  -- arquivo. Ninguém nota cinco pixels lendo o código, e todo mundo nota
  -- olhando a janela: o play afastado da borda e a engrenagem quase
  -- encostada nela.
  margem = 13,
}



-- Maximizada: enchendo a área útil do monitor. O tamanho E a posição de
-- antes ficam guardados, para restaurar devolver a janela ao lugar em
-- que ela estava — não a um tamanho padrão.
local maxi = { on = false, x = nil, y = nil, w = nil, h = nil }
-- Arrasto da pastilha. Como ela é pequena e clicar nela restaura, é
-- preciso distinguir clique de arrasto: guarda-se onde o mouse desceu e
-- só se restaura se ele não tiver andado (ver drawPastilha).
local pastilhaAtivaAntes = false
local pastilhaMoveu = false
-- Quadros restantes da transição de volta ao tamanho normal. Ver o
-- comentário em frame(): o SetWindowSize só vale no quadro seguinte.
-- PAINEL DE CONFIGURAÇÕES E REGISTRO, numa tabela só.
--
-- Estado irmão, e o teto de 200 locais por chunk do Lua não sobra para
-- uma variável por campo — este arquivo já o estourou três vezes (ver
-- test_integridade).
local painel = {
  compacto = false,  -- dentro do Avançado, esconder os ajustes
  aberto   = false,  -- mostrar ajustes e diagnóstico (ver drawToolbar)
  verbose  = false,  -- registrar tudo o que acontece
  salvoEm  = nil,    -- caminho do último registro salvo
  linhas   = {},     -- histórico mostrado dentro da própria janela
  -- PROCURA POR VERSÃO NOVA, na aba Sobre. Aqui e não num local próprio:
  -- o corpo deste módulo está no teto de 200 locais do Lua.
  atualizacao = { recado = nil, achada = nil, ocupado = false },
}

--- Registra uma linha de diagnóstico.
--
--  ATENÇÃO: esta função precisa vir DEPOIS de `local painel`. Antes ela
--  estava acima, e ali `painel.verbose` era uma global inexistente — sempre
--  nula. O resultado foi um log que nunca escrevia nada, e o defeito só
--  aparecia em tempo de execução.
--
--  O histórico vive na própria janela, num painel do modo avançado. O
--  console do REAPER não pode ser fechado por script, então usá-lo
--  significaria uma janela extra que só o usuário consegue tirar.
local function log(texto)
  if not painel.verbose then return end
  texto = tostring(texto):gsub('%s+$', '')
  if texto == '' then return end

  -- Carimbo com o tempo do projeto: numa investigação, saber QUANDO cada
  -- coisa aconteceu costuma valer mais que a mensagem em si.
  local carimbo = ''
  if Transport and Transport.isPlaying and Transport.isPlaying() then
    carimbo = Transport.formatTime(Transport.position()) .. '  '
  end

  painel.linhas[#painel.linhas + 1] = carimbo .. texto
  -- Guarda só o fim: um histórico infinito consome memória sem servir
  -- para nada, porque o que interessa é sempre o que acabou de ocorrer.
  while #painel.linhas > 500 do table.remove(painel.linhas, 1) end
end

--- Cabeçalho do registro: o AMBIENTE em que tudo aconteceu.
--
--  É a parte que mais falta quando se analisa um problema à distância.
--  Sem saber a grade, a compensação de atraso e a região, uma sequência
--  de eventos não diz muita coisa.
local function logHeader()
  local L = {}
  local function add(rotulo, valor)
    L[#L + 1] = ('  %-24s %s'):format(rotulo, tostring(valor))
  end

  L[#L + 1] = '=== LumiBridge — registro ==='
  add('data', os.date('%Y-%m-%d %H:%M:%S'))
  add('tela personalizada', layout and (layout.source or layout.name) or 'nenhum')
  if layout then
    local sum = Model.summary(layout)
    add('layout', ('%s · %d elementos · %d acionáveis · %d regras')
      :format(sum.size, sum.elements, sum.mapped, layout.stats.rules or 0))
  end
  add('porta MIDI', MidiOut.deviceName or 'nenhuma')
  add('motor de áudio', MidiOut.audioRunning() and 'rodando'
    or 'FECHADO — o MIDI não é entregue')
  add('track', Timeline.trackName or 'nenhuma')
  add('região', region and ('%s  (%.2f a %.2f s)')
    :format(region.name, region.startTime, region.endTime) or 'nenhuma')
  add('grade do editor', ('%.4f QN'):format(Timeline.projectGrid()))

  -- OS CANAIS MIDI EM USO. Eles vêm da Tela Personalizada, comando por
  -- comando — o LumiBridge não escolhe canal, ele obedece ao que o
  -- Lumikit exportou. Sem esta linha não havia como conferir isso sem
  -- abrir o .form num editor de texto.
  do
    local canais, lista = {}, {}
    for _, el in ipairs(layout and layout.elements or {}) do
      for _, cmd in ipairs(el.commands or {}) do
        if cmd.channel and not canais[cmd.channel] then
          canais[cmd.channel] = true
          lista[#lista + 1] = cmd.channel
        end
      end
    end
    table.sort(lista)
    add('canais MIDI da tela', #lista > 0
      and table.concat(lista, ', ') .. '   (definidos na Tela, não aqui)'
      or 'nenhum')
  end

  -- TECLAS DO TRANSPORTE: existem nesta versão do ReaImGui?
  --
  -- O Enter (play/pausa) já falhou neste projeto de dois jeitos que, na
  -- tela, parecem o mesmo nada: a constante da tecla não existir nesta
  -- geração da API, ou a tecla existir e não chegar até o script. Sem
  -- esta linha no cabeçalho do registro não dá para distinguir os dois
  -- sem outra rodada de perguntas.
  do
    local function const(nome)
      local v = Compat.const(ImGui, nome, nil)
      return v and tostring(v) or 'AUSENTE'
    end
    add('teclas', ('Enter=%s  EnterNum=%s  Espaço=%s')
      :format(const('Key_Enter'), const('Key_KeypadEnter'), const('Key_Space')))
  end
  add('atraso manual', ('%.0f ms'):format(latency * 1000))
  -- A taxa de quadros diz se a interface está saudável. Abaixo de uns
  -- 20 por segundo, cliques do mouse começam a se perder entre quadros
  -- e o sintoma aparece como "o botão não enviou".
  add('quadros por segundo', ('%.0f%s'):format(
    quadro.media > 0 and (1 / quadro.media) or 0,
    (quadro.media > 0.05) and '   <-- LENTO, cliques podem se perder' or ''))
  -- A REPARTIÇÃO, e não só o total: "está lento" sem dizer ONDE não
  -- ajuda ninguém a decidir o que desligar. As faixas entram na conta
  -- porque são o que dá para desligar.
  add('tempo por quadro',
    ('%.0f ms  (barra %.0f · onda %.0f · canvas %.0f · espelho %.0f'
     .. ' · faixas %.0f)')
    :format(perf.total * 1000, perf.barra * 1000, perf.onda * 1000,
            perf.canvas * 1000, perf.espelho * 1000,
            (perf.faixas or 0) * 1000))
  -- O PIOR QUADRO, que é o que uma pulada É. A média acima pode estar
  -- ótima e a tela trancar de segundo em segundo; sem esta linha os dois
  -- casos se descrevem com a mesma palavra.
  do
    local p = pico.ultimo or {}
    add('pior quadro (3 s)',
      ('%.0f ms  (barra %.0f · onda %.0f · canvas %.0f · espelho %.0f'
       .. ' · faixas %.0f)')
      :format((p.total or 0) * 1000, (p.barra or 0) * 1000,
              (p.onda or 0) * 1000, (p.canvas or 0) * 1000,
              (p.espelho or 0) * 1000, (p.faixas or 0) * 1000))
  end
  -- O INTERVALO ENTRE QUADROS, que é o que o olho vê. A linha de cima
  -- diz quanto tempo GASTAMOS; esta diz de quanto em quanto tempo a tela
  -- foi de fato redesenhada. As duas podem discordar muito.
  add('pior intervalo (3 s)', ('%.0f ms   ·   travadas acima de 100 ms: %d')
    :format(((pico.ultimo or {}).intervalo or 0) * 1000, quadro.travadas or 0))
  -- A MOLDURA se mexeu? Este número é sobre a JANELA no Windows, não
  -- sobre o desenho dentro dela. Parado, tem de ficar em zero.
  add('painel da tela personalizada', ('desenhado em %d de %d quadros%s')
    :format((quadro.canvasPedido or 0) - (quadro.canvasFalhou or 0),
            quadro.canvasPedido or 0,
            (quadro.canvasFalhou or 0) > 0 and '   <-- piscou' or ''))
  add('faixas desenhadas', ('%d linha(s) · %d segmento(s) de curva')
    :format(faixas.desenhadas or 0, faixas.segmentos or 0))
  add('movimentos da janela', ('%d desde que abriu%s')
    :format(geo.contadas or 0,
            (geo.contadas or 0) > 10 and '   <-- a janela está se mexendo' or ''))
  -- SE A TELA PARECE PULAR, este número separa "o layout está mudando
  -- de tamanho" de "está lento". São problemas diferentes e a adjetivo
  -- "pulando" serve para os dois.
  -- OS NÚMEROS DA BARRA. "O espaçamento continua igual" pode ser a conta
  -- errada ou a medida não acontecendo — e as duas se parecem na tela.
  -- "NÃO MEDIDO" quer dizer que nem GetCursorPosX nem GetCursorScreenPos
  -- responderam, e aí a folga fica no mínimo por falta de informação.
  -- A REPARTIÇÃO DA BARRA, em três números.
  --
  -- `contado` é o que manda: os blocos 1 a 3 somados por quem os
  -- desenha. `andou` é a mesma coisa medida percorrendo a linha, e serve
  -- só de conferência — divergindo dos dois, há item novo que ninguém
  -- somou. `vão` é o que sobra antes do último bloco: repartida, a barra
  -- o deixa do tamanho da folga (mais um espaçamento de leitura).
  add('barra: folga entre blocos', ('%d px'):format(encaixe.respiro or 0))
  add('barra: conteúdo contado', encaixe.barraConteudo
    and ('%d px'):format(encaixe.barraConteudo) or '—')
  add('barra: conteúdo medido', encaixe.barraUsado
    and ('%d px'):format(encaixe.barraUsado) or 'NÃO MEDIDO')
  add('barra: vão antes do último bloco', encaixe.barraSobra
    and ('%d px'):format(encaixe.barraSobra) or 'NÃO MEDIDO')
  add('reajustes da escala', ('%d desde que abriu'):format(encaixe.mudou or 0))
  -- AS PARCELAS SEPARADAS, e não só a soma.
  --
  -- Elas têm origens diferentes e sintomas diferentes: o atraso de saída
  -- vem do REAPER e costuma ser de poucos milissegundos — passando de
  -- cem, é a placa de áudio configurada com buffer grande, e vale saber
  -- disso antes de culpar a gravação. O meio quadro é nosso e é sempre
  -- pequeno. A soma sozinha não distingue os dois.
  add('atraso de saída (REAPER)', ('%.0f ms%s')
    :format(Timeline.outputLatency() * 1000,
            Timeline.outputLatency() > 0.1
              and '   <-- alto; confira o buffer da placa de áudio' or ''))
  add('meio quadro', ('%.0f ms'):format(Timeline.frameCompensation * 1000))
  add('compilação', tostring(Version.COMPILACAO))
  add('desconto total ao gravar', ('%.0f ms')
    :format((Timeline.outputLatency() + Timeline.frameCompensation
             + latency) * 1000))
  add('substituir ao regravar', Timeline.overwrite and 'sim' or 'não')
  -- Aberta fora de uma gravação, ela engole o desfazer de todas as
  -- edições manuais. Deve estar sempre em "não" com o REC desligado.
  add('sessão de desfazer aberta', Timeline.inSession() and 'SIM' or 'não')
  do
    local paraTras, paraFrente = Timeline.tamanhoDoHistorico()
    add('desfazer do editor', ('%d passo(s) atrás, %d à frente')
      :format(paraTras, paraFrente))
    add('próximo desfazer', Timeline.rotuloDesfazerEdicao()
      or ('(do REAPER) ' .. tostring(Transport.undoLabel())))
  end
  add('última edição guardada',
    Timeline.ultimaEdicaoGuardada == nil and 'nenhuma edição ainda'
    or (Timeline.ultimaEdicaoGuardada and 'sim'
        or 'NÃO — nada mudou nos itens'))
  do
    local porta, mudo = Timeline.saidaDaTrack()
    add('saída MIDI da track', porta
      and (('porta %d%s'):format(porta, mudo and '  (TRACK MUDA)' or ''))
      or 'nenhuma (só o LumiBridge manda)')
    add('espelho envia MIDI', espelho.envia and 'sim' or 'não')
    -- Duas fontes mandando a mesma nota fazem o Lumikit alternar duas
    -- vezes: o botão acende e apaga, e parece que não recebeu nada.
    add('espelho duplicaria a track', espelho.duplicaria() and 'SIM' or 'não')
  end
  L[#L + 1] = '--- eventos ---'
  return L
end

--- Todo o registro como texto, pronto para copiar ou salvar.
function logText()
  local L = logHeader()
  for i = 1, #painel.linhas do L[#L + 1] = painel.linhas[i] end
  return table.concat(L, '\n')
end

--- Grava o registro num arquivo de texto.
--
--  Fica logo depois de logText porque depende dela. Já esteve declarada
--  abaixo do botão que a chama, e ali era uma global inexistente — o
--  erro só aparecia quando o botão era clicado.
--
--  @return caminho, ou nil e a mensagem de erro
--- Pasta onde os registros são guardados.
--
--  Subpasta própria dentro dos recursos do REAPER: um arquivo solto no
--  meio de centenas de outros é difícil de achar quando se precisa dele.
local function logFolder()
  local base = reaper.GetResourcePath and reaper.GetResourcePath() or '.'
  local sep = package.config:sub(1, 1)
  local pasta = base .. sep .. 'LumiBridge' .. sep .. 'logs'
  if reaper.RecursiveCreateDirectory then
    reaper.RecursiveCreateDirectory(pasta, 0)
  end
  return pasta, sep
end

local function saveLog()
  local pasta, sep = logFolder()
  -- Nome com data e hora: guardar um histórico vale mais do que
  -- sobrescrever sempre o mesmo arquivo.
  local caminho = ('%s%sLumiBridge_%s.txt')
    :format(pasta, sep, os.date('%Y-%m-%d_%H-%M-%S'))

  local f, err = io.open(caminho, 'w')
  if not f then return nil, err end
  f:write(logText())
  f:close()
  return caminho
end

--- Copia texto para a área de transferência, pelo caminho disponível.
local function copyToClipboard(texto)
  if reaper.CF_SetClipboard then
    local ok = pcall(reaper.CF_SetClipboard, texto)
    if ok then return true end
  end
  if ImGui and ImGui.SetClipboardText then
    local ok = pcall(ImGui.SetClipboardText, ctx, texto)
    if ok then return true end
  end
  return false
end

--- Abre a pasta dos registros no explorador de arquivos.
local function openLogFolder()
  local pasta = logFolder()
  if reaper.CF_ShellExecute then
    pcall(reaper.CF_ShellExecute, pasta)
    return pasta
  end
  -- Sem a extensão SWS, o caminho é mostrado para copiar à mão.
  return pasta, true
end
local regions     = {}   -- regiões e marcadores do projeto
local shortcuts   = {}   -- { key = constante ImGui, element = ..., code = ... }
-- O QUE A TECLA ESTÁ SEGURANDO, e só ela.
--
-- Marca separada de propósito. Ver handleShortcuts: usar `session.holding`
-- aqui fazia o teclado soltar o que o MOUSE estava segurando.
local teclaSegura = {}

-- --------------------------------------------------- atalhos F1-F12

--- Chave do ExtState para os atalhos F1-F12 DESTA tela, ou nil se não
--  houver .form carregado ou o arquivo não trouxer freeFormHash (.form
--  muito antigo ou incompleto).
local function fkeyExtKey()
  if not layout or not layout.freeFormHash or layout.freeFormHash == '' then
    return nil
  end
  return EXT_FKEYS_PREFIX .. layout.freeFormHash
end

--- Relê os atalhos F1-F12 salvos para a tela carregada. Chamado sempre
--  que um .form é aberto — ver loadForm.
local function loadFKeys()
  local k = fkeyExtKey()
  if not k then fkeyMap = {} return end
  local texto = reaper.GetExtState(EXT_SECTION, k)
  fkeyMap = FKeys.decode(texto)
end

--- Grava os atalhos F1-F12 da tela atual.
local function saveFKeys()
  local k = fkeyExtKey()
  if not k then return end
  reaper.SetExtState(EXT_SECTION, k, FKeys.encode(fkeyMap), true)
end

--- Atribui a tecla `code` (F1-F12) ao controle `tag`.
--
--  Como o mapa é indexado por CÓDIGO, atribuir uma tecla já usada por
--  outro controle simplesmente troca o dono — sem precisar apagar a
--  entrada antiga em outro lugar. Reatribuição direta, sem aviso: é o
--  comportamento combinado (igual à maioria dos editores de atalho).
local function setFKey(code, tag)
  fkeyMap[code] = tag
  saveFKeys()
  -- Força reconstruir a lista de atalhos no próximo quadro (mesmo
  -- padrão do loadForm: shortcuts = {} some com o .built e o
  -- handleShortcuts remonta sozinho).
  shortcuts = {}
end

--- Remove qualquer tecla F1-F12 atualmente atribuída a `tag`.
local function clearFKeyForTag(tag)
  local mudou = false
  for code, t in pairs(fkeyMap) do
    if t == tag then fkeyMap[code] = nil mudou = true end
  end
  if mudou then
    saveFKeys()
    shortcuts = {}
  end
end

-- -------------------------------------------------- grupos de fader

--- Chave do ExtState para os grupos de fader DESTA tela, ou nil nas
--  mesmas condições de fkeyExtKey.
local function faderGroupsExtKey()
  if not layout or not layout.freeFormHash or layout.freeFormHash == '' then
    return nil
  end
  return EXT_FADERGROUPS_PREFIX .. layout.freeFormHash
end

--- Relê os grupos de fader salvos para a tela carregada. Chamado sempre
--  que um .form é aberto — ver loadForm.
local function loadFaderGroups()
  local k = faderGroupsExtKey()
  if not k then faderGroups = {} return end
  local texto = reaper.GetExtState(EXT_SECTION, k)
  faderGroups = FaderGroups.decode(texto)
end

--- Grava os grupos de fader da tela atual.
local function saveFaderGroups()
  local k = faderGroupsExtKey()
  if not k then return end
  reaper.SetExtState(EXT_SECTION, k, FaderGroups.encode(faderGroups), true)
end

-- ------------------------------------------- cores das faixas

--- Chave do ExtState para as cores escolhidas À MÃO nesta tela.
local function coresExtKey()
  if not layout or not layout.freeFormHash or layout.freeFormHash == '' then
    return nil
  end
  return EXT_LANECOLOR_PREFIX .. layout.freeFormHash
end

--- Recalcula as cores das faixas: o padrão vem do grupo "apenas um
--  ativo" declarado no .form, e por cima dele vale a escolha do usuário.
--
--  O PADRÃO PRECISA SER BOM, porque quase ninguém vai ajustar cor a cor.
--  Por isso ele sai da estrutura do arquivo em vez de um sorteio: os
--  membros de um grupo exclusivo se substituem, então uma troca de cor
--  na linha do tempo é exatamente uma troca de comando.
local function recarregarCores()
  if not layout then faixas.cores = {} return end
  faixas.cores, faixas.grupoDe = Lanes.palette(layout, Rules.index(layout))

  local k = coresExtKey()
  local texto = k and reaper.GetExtState(EXT_SECTION, k) or ''
  faixas.escolhidas = {}
  for tag, idx in texto:gmatch('(%d+):(%d+)') do
    tag, idx = tonumber(tag), tonumber(idx)
    local cor = Lanes.CORES[idx]
    if tag and cor then
      faixas.escolhidas[tag] = idx
      faixas.cores[tag] = cor
    end
  end
end

--- Fixa (ou solta) a cor de um controle. `idx` nil volta ao padrão.
local function escolherCor(tag, idx)
  if not tag then return end
  faixas.escolhidas = faixas.escolhidas or {}
  faixas.escolhidas[tag] = idx

  local partes = {}
  for t, i in pairs(faixas.escolhidas) do
    partes[#partes + 1] = ('%d:%d'):format(t, i)
  end
  table.sort(partes)

  local k = coresExtKey()
  if k then
    if #partes > 0 then
      reaper.SetExtState(EXT_SECTION, k, table.concat(partes, ';'), true)
    else
      reaper.DeleteExtState(EXT_SECTION, k, true)
    end
  end
  recarregarCores()
  faixas.at = 0
end

-- ------------------------------------------- controle do Release All

--- Chave do ExtState para o release ESCOLHIDO À MÃO nesta tela.
--
--  Por .form, como os atalhos e os grupos: qual controle é o release
--  depende de como AQUELA tela foi montada, não de uma preferência
--  global do usuário.
local function releaseExtKey()
  if not layout or not layout.freeFormHash or layout.freeFormHash == '' then
    return nil
  end
  return EXT_RELEASE_PREFIX .. layout.freeFormHash
end

--- Relê o release escolhido para a tela carregada — ver loadForm.
local function loadReleaseTag()
  if not session then return end
  local k = releaseExtKey()
  local tag = k and tonumber(reaper.GetExtState(EXT_SECTION, k)) or nil
  -- Uma tag que não existe mais (o .form foi reexportado e mudou) é
  -- descartada em silêncio: a busca por nome volta a valer, que é um
  -- palpite razoável, em vez de a tela ficar sem release nenhum.
  if tag and not session.byTag[tag] then tag = nil end
  Session.setReleaseTag(session, tag)
end

--- Grava o release escolhido para a tela atual.
local function saveReleaseTag(tag)
  if session then Session.setReleaseTag(session, tag) end
  local k = releaseExtKey()
  if not k then return end
  if tag then
    reaper.SetExtState(EXT_SECTION, k, tostring(tag), true)
  else
    reaper.DeleteExtState(EXT_SECTION, k, true)
  end
end

--- Menu de clique direito: atribui (ou remove) a tecla F1-F12 do
--  controle que recebeu o clique. `fkeyMenuElement` é preenchido pelo
--  evento 'rightclick' do laço do canvas, e o popup é aberto ali com
--  ImGui.OpenPopup — esta função só precisa desenhar o conteúdo todo
--  quadro, como qualquer popup do ImGui.
--- Abre um popup com folga em volta e devolve se ele está aberto.
--
--  A janela inteira tem WindowPadding zero, de propósito: com folga, a
--  barra de título e o painel não colam nas bordas como devem. Só que
--  POPUP TAMBÉM É JANELA, e herdava esse zero — o texto de um menu
--  encostava na borda dos quatro lados, o que lê como recorte, não como
--  desenho.
--
--  Quem abre popup chama isto e guarda o segundo retorno; ao fechar,
--  desempilha o mesmo tanto. Não virou uma função de fechar porque este
--  arquivo vive raspando o teto de 200 locais do Lua, e duas linhas no
--  lugar da chamada custam menos que um nome novo.
local function abrirPopup(id)
  local idPad = Compat.const(ImGui, 'StyleVar_WindowPadding', nil)
  local empilhou = false
  if idPad and ImGui.PushStyleVar then
    empilhou = pcall(ImGui.PushStyleVar, ctx, idPad, 10, 9)
  end
  local aberto = ImGui.BeginPopup(ctx, id)
  if not aberto and empilhou then pcall(ImGui.PopStyleVar, ctx, 1) end
  return aberto, empilhou
end

local function drawFKeyMenu()
  local aberto, padF = abrirPopup('fkeyMenu')
  if not aberto then return end
  local e = fkeyMenuElement
  if not e or not e.tag then
    ImGui.EndPopup(ctx)
    if padF then pcall(ImGui.PopStyleVar, ctx, 1) end
    return
  end

  ImGui.TextColored(ctx, 0x6B7280FF, e.text ~= '' and e.text or '(sem nome)')
  ImGui.Separator(ctx)

  for _, code in ipairs(FKeys.CODES) do
    local label = FKeys.label(code)
    local ownerTag = fkeyMap[code]
    local isThis = ownerTag == e.tag
    local rotulo = label
    if ownerTag and not isThis then
      local dono = session and session.byTag[ownerTag]
      local nome = dono and (dono.text ~= '' and dono.text or '(sem nome)') or '?'
      rotulo = ('%s   (%s)'):format(label, nome)
    end
    if ImGui.Selectable(ctx, rotulo, isThis) then
      setFKey(code, e.tag)
      ImGui.CloseCurrentPopup(ctx)
    end
  end

  ImGui.Separator(ctx)
  -- Remover quando não há atalho é um no-op inofensivo — mais simples
  -- que desabilitar o item, que exigiria BeginDisabled/EndDisabled
  -- (nem toda geração do ReaImGui traz essas duas funções).
  if ImGui.Selectable(ctx, 'Remover atalho') then
    clearFKeyForTag(e.tag)
    ImGui.CloseCurrentPopup(ctx)
  end

  ImGui.EndPopup(ctx)
  if padF then pcall(ImGui.PopStyleVar, ctx, 1) end
end

-- ------------------------------------------------------------ arquivo

local function loadForm(path)
  local newLayout, err = FormParser.parseFile(path)
  if not newLayout then
    loadError = err
    statusText = 'Falha ao carregar.'
    return false
  end

  layout    = newLayout
  loadError = nil
  session  = Session.new(layout)
  -- A grade vem do PROJETO, não fixa no código. Com um valor fixo de
  -- 1/16 num projeto em 1/32, o release ocupava dois quadradinhos e todo
  -- o resto deslocava junto.
  recorder = Recorder.new(Timeline.projectGrid())
  state.session = session
  shortcuts = {}
  loadFKeys()
  loadFaderGroups()
  loadReleaseTag()
  recarregarCores()
  groupSameTarget = {}
  groupWasHeld = {}
  -- Os ícones vêm do arquivo: trocar de .form troca os ícones.
  IconCache.reset()

  -- Se o arquivo trouxer algo que o parser não reconhece, o usuário
  -- precisa saber NA HORA. Sem isso, um tipo de grupo novo simplesmente
  -- não funcionaria e não haveria pista de por quê.
  auditWarning = nil
  local unknown = {}
  for key, count in pairs(layout.stats.unknownAttrs or {}) do
    unknown[#unknown + 1] = ('%s (%dx)'):format(key, count)
  end
  if #unknown > 0 then
    table.sort(unknown)
    auditWarning = 'Atributos não reconhecidos nesta tela personalizada: '
      .. table.concat(unknown, ', ')
      .. '  — o comportamento correspondente não será aplicado.'
  end

  local s = Model.summary(layout)
  statusText = ('%s  ·  %s  ·  %d elementos  ·  %d acionáveis  ·  %d regras')
    :format(s.name, s.size, s.elements, s.mapped, layout.stats.rules or 0)

  reaper.SetExtState(EXT_SECTION, EXT_LASTFILE, path, true)
  return true
end

local function browseForm()
  local last = reaper.GetExtState(EXT_SECTION, EXT_LASTFILE)
  local dir  = last ~= '' and last:match('^(.*)[/\\]') or ''
  local ok, path = reaper.GetUserFileNameForRead(dir, 'Selecione a Tela Personalizada (.form)', '.form')
  if ok and path and path ~= '' then loadForm(path) end
end

-- ---------------------------------------------------------- MIDI

local function refreshDevices()
  devices = MidiOut.listDevices()
end

--- Restaura a porta usada da última vez, procurando pelo NOME e não pelo
--  índice: o índice muda quando o usuário mexe nas portas do Windows, o
--  nome não. Escolher pelo índice mandaria MIDI para o lugar errado.
local function restoreDevice()
  refreshDevices()
  local saved = reaper.GetExtState(EXT_SECTION, EXT_MIDIPORT)
  local dev = MidiOut.findDeviceByName(saved)
  if dev then MidiOut.setDevice(dev.index, dev.name) end
end

local function chooseDevice(dev)
  MidiOut.setDevice(dev.index, dev.name)
  reaper.SetExtState(EXT_SECTION, EXT_MIDIPORT, dev.name, true)
end

local function drawMidiBar()
  -- A chave de envio vive na barra compacta; aqui fica só a escolha da
  -- porta, que é ajustada uma vez por sessão.
  --
  -- Duas linhas curtas, de propósito — igual à correção do corte em
  -- drawRecordBar (ver PROJECT_CONTEXT.md): texto + combo + dois botões
  -- numa fileira só passava de 500px e cortava sem aviso num cartão
  -- estreito.
  ajuste('Porta de saída', 'a mesma porta virtual (ex.: loopMIDI) que o Lumikit escuta.', 210)
  ImGui.SetNextItemWidth(ctx, 210)
  local preview = MidiOut.deviceName or 'selecione a porta de saída'
  if ImGui.BeginCombo(ctx, '##porta', preview) then
    if #devices == 0 then
      ImGui.Selectable(ctx, 'nenhuma porta de saída encontrada', false)
    end
    for _, dev in ipairs(devices) do
      local selected = (dev.index == MidiOut.deviceIndex)
      if ImGui.Selectable(ctx, dev.name, selected) then chooseDevice(dev) end
    end
    ImGui.EndCombo(ctx)
  end

  ajuste('Diagnóstico', 'testa se o Lumikit está recebendo, sem carregar um arquivo.', 175)
  if ImGui.Button(ctx, 'Reler portas', 100, 0) then refreshDevices() end
  dica('Relê a lista de portas MIDI do sistema.')
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Testar', 68, 0) then MidiOut.sendTestNote() end
  dica('Dispara uma nota de teste para conferir se o Lumikit está recebendo.')

  -- Resultado do diagnóstico: linha própria, cor conforme o estado.
  local msg = MidiOut.lastMessage
  if MidiOut.lastError then
    ImGui.TextColored(ctx, 0xFF6666FF, MidiOut.lastError)
  elseif msg then
    ImGui.TextColored(ctx, 0x88CC88FF, ('enviadas: %d  ·  última: %02X %d %d')
      :format(MidiOut.sentCount, msg.status, msg.data1, msg.data2))
  else
    ImGui.TextColored(ctx, 0x888888FF, 'nada enviado ainda')
  end
end

-- --------------------------------------------------------- barra

-- Declaradas aqui porque a barra as chama e elas só são definidas
-- adiante. Em Lua, uma `local function` posterior NÃO é visível acima do
-- ponto de declaração: a chamada resolveria para uma global inexistente
-- e só quebraria quando o botão fosse clicado.
local drawRecordBar
-- Declarada aqui porque startRecording precisa dela para o punch-in
-- dos botões marcados, e ela só é definida bem mais adiante.
local context
local closeOpenLines
local saltarPara
-- Estado do salto pela timeline. Ver saltarPara.
local saltoEmCurso = false
local saltoDestino = nil
-- Há um CAMPO DE TEXTO em edição neste quadro? Marcado pelos próprios
-- campos (só existem dois: a busca de músicas e a de faders) e lido por
-- handleShortcuts, que precisa se calar enquanto se digita. Ver lá o
-- porquê de não usar IsAnyItemActive.
local campoTextoAtivo = false

--- SetTooltip que respeita o interruptor. Todas as dicas da interface
--  passam por aqui: uma que continuasse chamando ImGui.SetTooltip
--  ignoraria a escolha do usuário, e seria justamente a que incomoda.
--- Um desenho do layout: caixa com a parte que a LISTA ocupa preenchida.
--
--  1 embaixo · 2 à direita · 3 a caixa inteira. É a mesma informação do
--  rótulo, na forma em que ela se lê sem ler — a escolha é de lugar, e
--  lugar se mostra melhor do que se descreve.
local function desenharLayout(dl, x, y, tam, modo, cor)
  ImGui.DrawList_AddRect(dl, x, y, x + tam, y + tam, cor, 2, 0, 1.2)
  local m = 2
  if modo == 1 then
    ImGui.DrawList_AddRectFilled(dl, x + m, y + tam * 0.5, x + tam - m,
                                 y + tam - m, cor, 1)
  elseif modo == 2 then
    ImGui.DrawList_AddRectFilled(dl, x + tam * 0.5, y + m, x + tam - m,
                                 y + tam - m, cor, 1)
  else
    ImGui.DrawList_AddRectFilled(dl, x + m, y + m, x + tam - m,
                                 y + tam - m, cor, 1)
  end
end


local function dicaSe(texto)
  if not (opcoes.dicas and texto) then return end

  -- BORDA E FOLGA NA DICA.
  --
  -- Uma dica é uma JANELA do ImGui, e herdava o WindowPadding zero e a
  -- ausência de borda da janela principal: texto encostado nos quatro
  -- lados de um retângulo sem contorno, sobre um fundo de cor vizinha.
  -- O PopupBorderSize que resolveu os menus não a alcança — dica não é
  -- popup, e essa distinção do ImGui é exatamente o que me fez achar que
  -- já estava resolvido.
  local n = 0
  local idPad = Compat.const(ImGui, 'StyleVar_WindowPadding', nil)
  if idPad and ImGui.PushStyleVar
     and pcall(ImGui.PushStyleVar, ctx, idPad, 10, 8) then n = n + 1 end
  local idBorda = Compat.const(ImGui, 'StyleVar_WindowBorderSize', nil)
  if idBorda and ImGui.PushStyleVar
     and pcall(ImGui.PushStyleVar, ctx, idBorda, 1) then n = n + 1 end

  ImGui.SetTooltip(ctx, texto)

  if n > 0 then pcall(ImGui.PopStyleVar, ctx, n) end
end
-- Foco do quadro anterior, para registrar só as TRANSIÇÕES.
local focoAnterior = nil

--- Desenha uma aba do painel de configurações.
--
--  A aba escolhida fica lembrada entre sessões. Só o conteúdo de uma
--  aba aparece por vez, que é o ponto: vinte controles empilhados sem
--  hierarquia obrigavam a varrer a barra inteira para achar um ajuste.
--
--  @return boolean esta aba está selecionada?
function aba(titulo, chave, primeira)
  if not primeira then ImGui.SameLine(ctx, 0, 2) end

  local ativa = (abaAtual == chave)

  local n = 0
  local idBtn = Compat.const(ImGui, 'Col_Button', nil)
  local idTxt = Compat.const(ImGui, 'Col_Text', nil)
  if idBtn and ImGui.PushStyleColor then
    if pcall(ImGui.PushStyleColor, ctx, idBtn,
             ativa and 0x22364DFF or 0x00000000) then n = n + 1 end
    if idTxt and pcall(ImGui.PushStyleColor, ctx, idTxt,
             ativa and 0x8FBEFFFF or 0x7A8290FF) then n = n + 1 end
  end

  local clicou = ImGui.Button(ctx, titulo)

  if n > 0 and ImGui.PopStyleColor then pcall(ImGui.PopStyleColor, ctx, n) end

  if clicou then
    abaAtual = chave
    reaper.SetExtState(EXT_SECTION, 'aba', chave, true)
  end

  return ativa
end

--- Rótulo de um grupo de controles dentro da aba.
local function rotulo(texto)
  ImGui.TextColored(ctx, 0x5F6672FF, texto)
end

--- Mostra uma dica se o cursor estiver sobre o último item desenhado.
--
--  Existe como função para que a dica seja adicionada numa linha só, em
--  cada controle. Sem isso, o padrão de três linhas se repetiria dezenas
--  de vezes e acabaria faltando em metade dos botões.
function dica(texto)
  if texto and ImGui.IsItemHovered(ctx) then
    dicaSe( texto)
  end
end

--- Início de uma linha de ajuste das Configurações: nome em destaque e
--  explicação complementar à esquerda, controle à direita — o formato
--  do mockup aprovado (ver PROJECT_CONTEXT.md, "Pendências conhecidas").
--  Uma linha por ajuste, o que também torna o corte impossível em
--  qualquer largura do cartão: o controle nunca some, só o texto da
--  explicação fica mais apertado.
--
--  Mede a largura disponível ANTES de desenhar qualquer texto — é essa
--  medida, tirada na margem esquerda da linha, que dá a coordenada certa
--  pro SameLine final pular direto pra ela, não importa quantos textos
--  vieram antes na mesma linha.
--
--  O controle em si é responsabilidade de quem chama, desenhado logo
--  depois desta função, com um rótulo "##algumacoisa" (sem texto visível
--  à direita do controle — o texto já foi desenhado aqui à esquerda).
--
--  @param nome        rótulo em destaque
--  @param explicacao  texto complementar, discreto (pode ser nil/vazio)
--  @param controlW    espaço reservado à direita para o controle
function ajuste(nome, explicacao, controlW)
  local largura = ImGui.GetContentRegionAvail(ctx)
  ImGui.TextColored(ctx, Theme.UI.text, nome)
  if explicacao and explicacao ~= '' then
    ImGui.SameLine(ctx)
    ImGui.TextColored(ctx, Theme.UI.textDim, explicacao)
  end
  ImGui.SameLine(ctx, math.max(0, largura - controlW))
end

--- Linha de ajuste liga/desliga: nome e explicação à esquerda, um
--  INTERRUPTOR (pílula, não caixinha) à direita. A linha inteira é
--  clicável e destaca ao passar o mouse — pedido explícito, porque uma
--  caixinha isolada lá na ponta direita, longe do texto, era difícil
--  de acompanhar: não dava pra saber de relance qual linha o clique ia
--  acertar.
--
--  Desenhado à mão com DrawList (retângulo arredondado + círculo),
--  como o resto dos controles do LumiBridge — NÃO uma imagem: são só
--  duas primitivas simples (nenhum triângulo fino, nenhuma malha), o
--  tipo de forma que não sofre da armadilha de suavização documentada
--  em PROJECT_CONTEXT.md para os ícones da barra.
--
--  @param nome        rótulo em destaque
--  @param explicacao  texto complementar, discreto (pode ser nil/vazio)
--  @param valor       estado atual (true/false)
--  @param dicaTexto   texto completo da dica ao passar o mouse (opcional)
--  @return mudou, novoValor
function ajusteToggle(nome, explicacao, valor, dicaTexto)
  local largura = ImGui.GetContentRegionAvail(ctx)
  local ALTURA = 28
  local x0, y0 = ImGui.GetCursorScreenPos(ctx)
  x0, y0 = math.floor(x0), math.floor(y0)

  ImGui.InvisibleButton(ctx, '##toggle_' .. nome, largura, ALTURA)
  local hovered = ImGui.IsItemHovered(ctx)
  local clicked = ImGui.IsItemClicked(ctx)

  -- A dica precisa ser checada AQUI, contra o InvisibleButton — depois
  -- que a função voltar, o último "item" pro ImGui já vai ser outra
  -- coisa (o desenho da pílula), e um dica() chamado pelo chamador
  -- estaria conferindo o item errado.
  if dicaTexto and hovered then
    dicaSe( dicaTexto)
  end

  local dl = ImGui.GetWindowDrawList(ctx)
  if hovered then
    ImGui.DrawList_AddRectFilled(dl, x0, y0, x0 + largura, y0 + ALTURA, Theme.UI.panelHover, 5)
  end

  ImGui.SetCursorScreenPos(ctx, x0 + 8, y0 + 6)
  ImGui.TextColored(ctx, Theme.UI.text, nome)
  if explicacao and explicacao ~= '' then
    ImGui.SameLine(ctx)
    ImGui.TextColored(ctx, Theme.UI.textDim, explicacao)
  end

  local swW, swH = 34, 18
  local swX = x0 + largura - swW - 10
  local swY = y0 + (ALTURA - swH) * 0.5
  local corFundo = valor and Theme.UI.accent or 0x3A3F4AFF
  ImGui.DrawList_AddRectFilled(dl, swX, swY, swX + swW, swY + swH, corFundo, swH * 0.5)
  local raio = swH * 0.5 - 2
  local botaoX = valor and (swX + swW - swH * 0.5) or (swX + swH * 0.5)
  ImGui.DrawList_AddCircleFilled(dl, botaoX, swY + swH * 0.5, raio, 0xF5F7FAFF)

  -- Devolve o cursor pro fim da linha inteira (altura do InvisibleButton),
  -- não onde os desenhos acima deixaram — sem isso a próxima linha
  -- desenharia por cima da pílula.
  ImGui.SetCursorScreenPos(ctx, x0, y0 + ALTURA)

  if clicked then return true, not valor end
  return false, valor
end

--- Controle de dois segmentos: duas opções NOMEADAS lado a lado, a
--  ativa em destaque. Para uma escolha entre dois estados com nome
--  (tipo "Diferença" / "Mesmo valor"), onde um interruptor genérico
--  não diz pra que lado ele está — precisaria ler o texto da
--  explicação puro pra saber o que "ligado" significa.
--
--  Larguras dos segmentos são FIXAS (as duas opções deste controle são
--  sempre as mesmas duas palavras), mas o TEXTO dentro delas é medido
--  com CalcTextSize e centrado nos dois eixos — um deslocamento fixo em
--  pixel deixava a palavra visivelmente abaixo do centro, e o valor
--  certo depende da altura da fonte, que varia com a versão do
--  ReaImGui (ver Theme.createFonts: a 0.10 tem fonte escalável).
--  CalcTextSize já é usado em ui/renderer.lua, é rota conhecida.
--
--  @param nome               rótulo à esquerda
--  @param opcaoEsq, opcaoDir texto de cada segmento
--  @param direita            true se o segmento da direita está ativo
--  @return mudou, novoDireita
function segmento2(nome, opcaoEsq, opcaoDir, direita)
  local WESQ, WDIR, ALTURA = 84, 104, 24
  local largTotal = WESQ + WDIR
  local largura = ImGui.GetContentRegionAvail(ctx)

  ImGui.TextColored(ctx, Theme.UI.text, nome)
  ImGui.SameLine(ctx, largura - largTotal)

  local x0, y0 = ImGui.GetCursorScreenPos(ctx)
  x0, y0 = math.floor(x0), math.floor(y0)
  local dl = ImGui.GetWindowDrawList(ctx)

  ImGui.DrawList_AddRectFilled(dl, x0, y0, x0 + largTotal, y0 + ALTURA, Theme.UI.panel, ALTURA * 0.5)

  ImGui.SetCursorScreenPos(ctx, x0, y0)
  ImGui.InvisibleButton(ctx, '##seg_esq_' .. nome, WESQ, ALTURA)
  local clicouEsq = ImGui.IsItemClicked(ctx)

  ImGui.SetCursorScreenPos(ctx, x0 + WESQ, y0)
  ImGui.InvisibleButton(ctx, '##seg_dir_' .. nome, WDIR, ALTURA)
  local clicouDir = ImGui.IsItemClicked(ctx)

  if direita then
    ImGui.DrawList_AddRectFilled(dl, x0 + WESQ + 2, y0 + 2, x0 + largTotal - 2, y0 + ALTURA - 2,
      Theme.UI.accent, (ALTURA - 4) * 0.5)
  else
    ImGui.DrawList_AddRectFilled(dl, x0 + 2, y0 + 2, x0 + WESQ - 2, y0 + ALTURA - 2,
      Theme.UI.accent, (ALTURA - 4) * 0.5)
  end

  local wEsq, hEsq = ImGui.CalcTextSize(ctx, opcaoEsq)
  ImGui.SetCursorScreenPos(ctx,
    math.floor(x0 + (WESQ - wEsq) * 0.5),
    math.floor(y0 + (ALTURA - hEsq) * 0.5))
  ImGui.TextColored(ctx, not direita and 0x04294FFF or Theme.UI.textDim, opcaoEsq)

  local wDir, hDir = ImGui.CalcTextSize(ctx, opcaoDir)
  ImGui.SetCursorScreenPos(ctx,
    math.floor(x0 + WESQ + (WDIR - wDir) * 0.5),
    math.floor(y0 + (ALTURA - hDir) * 0.5))
  ImGui.TextColored(ctx, direita and 0x04294FFF or Theme.UI.textDim, opcaoDir)

  ImGui.SetCursorScreenPos(ctx, x0, y0 + ALTURA)

  if clicouEsq and direita then return true, false end
  if clicouDir and not direita then return true, true end
  return false, direita
end

--- Linha de item marcável (fader de um grupo): nome à esquerda, uma
--  marca de seleção à direita — mesmo padrão de linha inteira
--  clicável do ajusteToggle, mas com visual de caixa de seleção (não
--  interruptor): aqui é escolher VÁRIOS itens de uma lista, não ligar
--  um ajuste só.
--  @return mudou, novoMarcado
local function itemMarcavel(id, nome, marcado)
  local largura = ImGui.GetContentRegionAvail(ctx)
  local ALTURA = 26
  local x0, y0 = ImGui.GetCursorScreenPos(ctx)
  x0, y0 = math.floor(x0), math.floor(y0)

  ImGui.InvisibleButton(ctx, '##item_' .. tostring(id), largura, ALTURA)
  local hovered = ImGui.IsItemHovered(ctx)
  local clicked = ImGui.IsItemClicked(ctx)

  local dl = ImGui.GetWindowDrawList(ctx)
  if hovered then
    ImGui.DrawList_AddRectFilled(dl, x0, y0, x0 + largura, y0 + ALTURA, Theme.UI.panelHover, 4)
  end

  local caixaY = y0 + (ALTURA - 15) * 0.5
  if marcado then
    ImGui.DrawList_AddRectFilled(dl, x0 + 8, caixaY, x0 + 23, caixaY + 15, Theme.UI.accent, 3)
    ImGui.DrawList_AddLine(dl, x0 + 11, caixaY + 8, x0 + 15, caixaY + 12, 0x04294FFF, 2)
    ImGui.DrawList_AddLine(dl, x0 + 15, caixaY + 12, x0 + 20, caixaY + 4, 0x04294FFF, 2)
  else
    ImGui.DrawList_AddRect(dl, x0 + 8, caixaY, x0 + 23, caixaY + 15, 0x4A5568FF, 3)
  end

  ImGui.SetCursorScreenPos(ctx, x0 + 32, y0 + 5)
  ImGui.TextColored(ctx, marcado and Theme.UI.text or Theme.UI.textDim, nome)

  ImGui.SetCursorScreenPos(ctx, x0, y0 + ALTURA)

  if clicked then return true, not marcado end
  return false, marcado
end

--- Linha da lista de atalhos: a TECLA num quadradinho estilo tecla de
--  teclado, o nome do controle ao lado, e (quando removível) um × na
--  ponta direita que só aparece com o mouse na linha.
--
--  A tecla num quadradinho de largura FIXA resolve dois problemas de
--  uma vez: alinha os nomes todos na mesma coluna (antes o alinhamento
--  vinha de um '%-4s' no format, que só funciona em fonte
--  monoespaçada — e a fonte da interface não é) e dá peso visual à
--  tecla, que é a informação que se procura ao bater o olho na lista.
--
--  @param id        sufixo único do ID interno
--  @param tecla     texto da tecla ('B', 'F1', ...)
--  @param nome      nome do controle, ou nil se a tecla está livre
--  @param etiqueta  texto de uma etiqueta discreta ao lado (ex.: 'oculto')
--  @param removivel mostra o × no hover?
--  @return clicouRemover
local function linhaAtalho(id, tecla, nome, etiqueta, removivel)
  local largura = ImGui.GetContentRegionAvail(ctx)
  local ALTURA, TECLA_W, TECLA_H = 26, 32, 20
  local x0, y0 = ImGui.GetCursorScreenPos(ctx)
  x0, y0 = math.floor(x0), math.floor(y0)
  local livre = (nome == nil)

  ImGui.InvisibleButton(ctx, '##atalho_' .. tostring(id), largura, ALTURA)
  local hovered = ImGui.IsItemHovered(ctx)

  local dl = ImGui.GetWindowDrawList(ctx)
  if hovered and not livre then
    ImGui.DrawList_AddRectFilled(dl, x0, y0, x0 + largura, y0 + ALTURA, Theme.UI.panelHover, 4)
  end

  -- Quadradinho da tecla. Livre = só contorno apagado, sem preenchimento:
  -- as teclas não usadas somem do primeiro olhar, sem sumir da lista.
  local tx, ty = x0 + 8, y0 + (ALTURA - TECLA_H) * 0.5
  if livre then
    ImGui.DrawList_AddRect(dl, tx, ty, tx + TECLA_W, ty + TECLA_H, 0x333947FF, 4)
  else
    ImGui.DrawList_AddRectFilled(dl, tx, ty, tx + TECLA_W, ty + TECLA_H, 0x22262FFF, 4)
    ImGui.DrawList_AddRect(dl, tx, ty, tx + TECLA_W, ty + TECLA_H, 0x333947FF, 4)
  end

  local wT, hT = ImGui.CalcTextSize(ctx, tecla)
  ImGui.SetCursorScreenPos(ctx,
    math.floor(tx + (TECLA_W - wT) * 0.5), math.floor(ty + (TECLA_H - hT) * 0.5))
  ImGui.TextColored(ctx, livre and 0x5F6672FF or 0xC7CDD8FF, tecla)

  ImGui.SetCursorScreenPos(ctx, x0 + 8 + TECLA_W + 10, y0 + 4)
  ImGui.TextColored(ctx, livre and 0x5F6672FF or Theme.UI.text, nome or 'livre')

  if etiqueta then
    ImGui.SameLine(ctx)
    local ex, ey = ImGui.GetCursorScreenPos(ctx)
    local wE, hE = ImGui.CalcTextSize(ctx, etiqueta)
    ImGui.DrawList_AddRectFilled(dl, ex, math.floor(ey - 1),
      math.floor(ex + wE + 12), math.floor(ey + hE + 3), 0x22262FFF, 4)
    ImGui.SetCursorScreenPos(ctx, math.floor(ex + 6), ey + 1)
    ImGui.TextColored(ctx, Theme.UI.textDim, etiqueta)
  end

  -- O × só na linha sob o mouse: uma coluna de botões sempre visível
  -- competia com os nomes, que são o conteúdo de verdade da lista.
  --
  -- Área clicável PRÓPRIA, desenhada DEPOIS da linha: remover é
  -- destrutivo, não pode disparar num clique em qualquer ponto da
  -- linha. No ImGui quem vem depois ganha o mouse, então este botão
  -- pequeno vence a linha inteira embaixo dele.
  local clicouRemover = false
  if removivel and hovered then
    local X_W = 24
    local bx = x0 + largura - X_W - 6
    ImGui.SetCursorScreenPos(ctx, bx, y0)
    ImGui.InvisibleButton(ctx, '##rmatalho_' .. tostring(id), X_W, ALTURA)
    local sobreX = ImGui.IsItemHovered(ctx)
    if ImGui.IsItemClicked(ctx) then clicouRemover = true end

    local wX, hX = ImGui.CalcTextSize(ctx, 'x')
    ImGui.SetCursorScreenPos(ctx,
      math.floor(bx + (X_W - wX) * 0.5), math.floor(y0 + (ALTURA - hX) * 0.5))
    ImGui.TextColored(ctx, sobreX and Theme.UI.rec or Theme.UI.textDim, 'x')
  end

  ImGui.SetCursorScreenPos(ctx, x0, y0 + ALTURA)
  return clicouRemover
end

-- --------------------------------------------------- ícone do programa
--
-- A grade de botões da Janela Personalizada do Lumikit, alguns acesos:
-- é o que o usuário reconhece de imediato. Âmbar são as luzes acesas,
-- azul são os controles ligados ao MIDI, escuro os apagados.
--
-- Desenhado com retângulos, e só: nenhuma linha fina, nenhum triângulo
-- — as formas que PROJECT_CONTEXT.md registra como as que sofrem com a
-- suavização do ImGui. Isso o mantém nítido em 18px, o menor tamanho
-- em que ele aparece (a pastilha do chrome.minimizado).
--
-- Declarado AQUI, no alto, porque é usado em três lugares bem
-- separados: a aba Sobre, a barra de título e a pastilha. Já esteve
-- mais abaixo e o test_globals pegou — a aba Sobre o chamava antes da
-- declaração.
--
--  @param corUnica  se informado, pinta TODAS as células acesas nessa
--                   cor — usado para o estado gravando, em que o ícone
--                   inteiro fica vermelho
local function desenharIconeApp(dl, x, y, tam, corUnica)
  local c = tam / 48
  local LADO = 10 * c
  local COLS = { 7 * c, 19 * c, 31 * c }
  local LINS = { 8 * c, 20 * c, 32 * c }

  local ACESA, MIDI, APAGADA = 0xF5A524FF, 0x3D8BFDFF, 0x2A2F3AFF
  local GRADE = {
    { APAGADA, ACESA,   APAGADA },
    { ACESA,   APAGADA, MIDI    },
    { APAGADA, MIDI,    APAGADA },
  }

  for lin = 1, 3 do
    for col = 1, 3 do
      local cor = GRADE[lin][col]
      if corUnica and cor ~= APAGADA then cor = corUnica end
      local cx = math.floor(x + COLS[col])
      local cy = math.floor(y + LINS[lin])
      ImGui.DrawList_AddRectFilled(dl, cx, cy,
        math.floor(cx + LADO), math.floor(cy + LADO), cor, 2 * c)
    end
  end
end

--- Empilha uma cor de fundo de child (Col_ChildBg), devolvendo quantas
--  cores empilhar de volta no Pop correspondente — 0 se a constante não
--  existir nesta versão do ReaImGui ou se o push falhar.
--
--  Compartilhada entre drawSettingsPanel (véu, cartão, moldura) e
--  qualquer trecho de aba que precise do mesmo truque de "child
--  preenchido" — como o campo do log, num tom diferente do resto do
--  cartão. Antes vivia só dentro de drawSettingsPanel; precisou subir
--  pra cá pra ficar visível de dentro de drawAbaAtual também.
local function empilhaFundo(cor)
  local idChildBg = Compat.const(ImGui, 'Col_ChildBg', nil)
  if idChildBg and pcall(ImGui.PushStyleColor, ctx, idChildBg, cor) then
    return 1
  end
  return 0
end

-- NÃO EXISTE LIMITE DE CRESCIMENTO.
--
-- Houve uma versão em que a linha parava no próximo evento já gravado,
-- para que uma mudança valesse só até a troca seguinte. O comportamento
-- definido depois é outro, e é o que vale: do clique até o STOP aquele
-- grupo é do usuário, e a nota atravessa quantos eventos houver.
--
-- O que estava programado adiante não se perde: é guardado como cauda
-- (ver Timeline.restoreTails) e devolvido a partir do ponto do stop.

--- Prepara a música: item do tamanho da região e Release All no primeiro
--- quadradinho.
--
--  É o passo que elimina o trabalho manual: escolher a região basta.
--  Idempotente — preparar duas vezes a mesma região não duplica o
--  release, porque a escrita substitui o que já estava naquele ponto.
--- Garante que exista o item MIDI da região, SEM escrever nada nele.
--
--  Criar o item é inofensivo: um recipiente vazio não muda a luz nem a
--  programação. É separado do "Preparar" de propósito — aquele escreve
--  release e estado inicial, e por isso só pode acontecer quando você
--  pede explicitamente.
--
--  Também é o que permite ler a grade do EDITOR MIDI, que só existe a
--  partir de um take.
local function ensureItem()
  if not region or not Timeline.isReady() then return false end
  local take = Timeline.prepareRegion(region.startTime, region.endTime,
                                      region.name)
  if take then Waveform.reset() end
  return take ~= nil
end

local function prepareSongCru(silent)
  -- DIZ O QUE FALTA, em vez de não fazer nada.
  --
  -- Antes bastava faltar a track para o botão parecer quebrado: ele
  -- retornava em silêncio e nada acontecia na tela.
  local faltando
  if not session then faltando = 'nenhuma tela personalizada carregada'
  elseif not region then faltando = 'nenhuma música selecionada'
  elseif not Timeline.isReady() then
    faltando = 'nenhuma track escolhida (Configurações > Gravação)'
  end

  if faltando then
    log('preparar impedido: ' .. faltando)
    if not silent then
      reaper.MB('Não é possível preparar:\n\n' .. faltando,
                'LumiBridge', 0)
    end
    return false
  end

  local take = Timeline.prepareRegion(region.startTime, region.endTime,
                                      region.name)
  if not take then
    if Timeline.lastError and not silent then
      reaper.MB(('Não foi possível preparar "%s":\n\n%s')
        :format(region.name, Timeline.lastError), 'LumiBridge', 0)
    end
    log('preparar recusado: ' .. tostring(Timeline.lastError))
    return false
  end

  Waveform.reset()

  -- RELEASE ALL no primeiro quadradinho, e o ESTADO INICIAL no segundo.
  --
  -- Isto acontece só aqui, no "Preparar", que é o ato explícito de
  -- começar uma música do zero. O REC nunca escreve nada por conta
  -- própria: no meio de uma música já pronta, ele apenas ouve.
  if recorder then
    Recorder.setGrid(recorder, Timeline.projectGrid())

    local marcados = {}
    for tag, on in pairs(session.active) do
      if on and not session.faderTags[tag] then
        local e = session.byTag[tag]
        if e and e.commands and #e.commands > 0 then marcados[#marcados + 1] = e end
      end
    end
    table.sort(marcados, function(a, b) return (a.tag or 0) < (b.tag or 0) end)

    local release = preparo.release and Session.findRelease(session) or nil
    local qn = Timeline.timeToQN(region.startTime)
    local out = Recorder.openSong(recorder, release, marcados, qn)
    if #out > 0 then Timeline.write(out) end
    if preparo.release and not release then
      log('sem release: nenhum controle desta tela está marcado como '
        .. 'Release All (Configurações > Preparo)')
    end
  end

  -- FADERS: um ponto no começo e outro no fim da música.
  --
  -- O valor sai da escolha em Configurações > Preparo. Em 100% a música
  -- abre com tudo no máximo, que é como quase toda música começa; na
  -- POSIÇÃO ATUAL ela abre como os faders estão na tela, e deixar o
  -- GERAL em zero antes de preparar faz a música nascer em zero.
  --
  -- Quais faders existem vem do .form: outro arquivo pode ter três ou
  -- dez, e o código não precisa saber.
  if preparo.faders and recorder and session then
    local pontos = {}
    for tag, element in pairs(session.byTag) do
      if session.faderTags[tag] then
        for _, cmd in ipairs(element.commands or {}) do
          if (cmd.status & 0xF0) == 0xB0 then
            local valor = preparo.cem and 127 or Session.faderCC(session, tag)
            pontos[#pontos + 1] = { kind = 'cc', channel = cmd.channel,
              cc = cmd.data1, value = valor,
              qn = Timeline.timeToQN(region.startTime) }
            pontos[#pontos + 1] = { kind = 'cc', channel = cmd.channel,
              cc = cmd.data1, value = valor,
              qn = Timeline.timeToQN(region.endTime) - recorder.gridQN }
            break
          end
        end
      end
    end
    if #pontos > 0 then
      Timeline.write(pontos)
      -- Diz o valor de verdade. Este registro dizia "em 100%" sempre,
      -- mesmo quando escrevia a posição atual do fader — e olhar o log
      -- para entender uma música que abriu escura não levava a lugar
      -- nenhum.
      log(('%d ponto(s) de fader (%s)'):format(#pontos,
        preparo.cem and '100%' or 'posição atual'))
    end
  end

  quadro.preparada = region.name
  if not silent then
    log(('música preparada: %s  (%.1f s)')
      :format(region.name, region.endTime - region.startTime))
  end
  return true
end

--- Trecho da música visível AGORA, em segundos.
--
--  UMA VISTA SÓ, compartilhada pela forma de onda e pelas faixas de
--  programação. É o alinhamento vertical entre as duas que responde
--  "esta nota cai em cima desta batida?" — dar zoom só numa delas
--  destruiria exatamente a razão de as faixas existirem.
--
--  Sem zoom (o normal) é a música inteira. `faixas.vDe/vAte` só existem
--  depois de alguém girar a roda, e são sempre limitados à região: não
--  há como sair da música por engano e ficar olhando o vazio.
local function vistaDaMusica()
  if not region then
    local pos = Transport.position()
    return math.max(0, pos - 15), pos + 15
  end
  local de = math.max(region.startTime, faixas.vDe or region.startTime)
  local ate = math.min(region.endTime, faixas.vAte or region.endTime)
  if ate - de < 0.25 then return region.startTime, region.endTime end

  -- A VISTA ACOMPANHA A REPRODUÇÃO quando está aproximada.
  --
  -- Sem zoom a música inteira já está na tela e não há o que seguir. Com
  -- zoom, o cursor saía pela direita e a tela continuava mostrando um
  -- trecho que já passou: para acompanhar, era preciso arrastar a vista
  -- à mão enquanto a música tocava — justamente quando as mãos estão
  -- ocupadas.
  --
  -- SALTA DE PÁGINA, não rola continuamente. Uma vista que desliza a
  -- cada quadro deixa o desenho inteiro em movimento e é muito pior de
  -- ler do que uma que fica parada e pula quando precisa.
  --
  -- O CURSOR VAI ATÉ O FIM DA JANELA antes de a vista mudar, como no
  -- próprio REAPER. Estava saltando a 85% do caminho, e isso desperdiça
  -- a última fatia da tela: o trecho que está chegando é justamente o
  -- que se quer ver com antecedência, e ele sumia antes de ser
  -- alcançado. Chegando na borda, a página vira e o cursor reaparece
  -- colado na esquerda, com a música inteira à frente.
  --
  -- Só ao TOCAR: parado, a vista é de quem está olhando, e mover a tela
  -- sozinha embaixo de uma edição em curso seria pior que não seguir.
  if faixas.seguirCursor and Transport.isPlaying() then
    local dur = ate - de
    local pos = Transport.position()
    if pos >= ate or pos < de then
      -- Uma lasquinha antes do cursor: colado no zero ele fica em cima
      -- da borda e some meio pixel dentro dela.
      de = math.max(region.startTime, pos - dur * 0.02)
      ate = math.min(region.endTime, de + dur)
      de = math.max(region.startTime, ate - dur)
      faixas.vDe, faixas.vAte = de, ate
    end
  end

  return de, ate
end

--- Aplica um passo de zoom horizontal em torno de um instante.
--
--  EM TORNO DO MOUSE, não do centro: o ponto sob o cursor fica onde
--  está e o resto se aproxima dele. É como se navega num editor de
--  áudio, e é o que permite mirar um trecho sem precisar de barra de
--  rolagem nenhuma — aproximar já arrasta a vista para lá.
local function zoomHorizontal(passos, foco)
  if not region then return end
  local de, ate = vistaDaMusica()
  local dur = ate - de
  local fator = 0.8 ^ passos
  local nova = dur * fator

  local inteira = region.endTime - region.startTime
  if nova >= inteira then
    faixas.vDe, faixas.vAte = nil, nil
    return
  end
  -- Um mínimo de meio segundo: abaixo disso não se enxerga contexto
  -- nenhum e cada giro da roda vira um salto.
  if nova < 0.5 then nova = 0.5 end

  local f = (foco - de) / dur
  if f < 0 then f = 0 elseif f > 1 then f = 1 end
  local novoDe = foco - nova * f
  local novoAte = novoDe + nova

  if novoDe < region.startTime then
    novoDe, novoAte = region.startTime, region.startTime + nova
  end
  if novoAte > region.endTime then
    novoAte, novoDe = region.endTime, region.endTime - nova
  end
  faixas.vDe, faixas.vAte = novoDe, novoAte
end

--- Timeline visual: forma de onda da música, régua de tempo e cursor.
--
--  Clicar move o cursor. Ver a onda é o que permite achar o refrão ou a
--  virada de relance, em vez de adivinhar por número de segundos.
--- @param xF, yF, larguraF  onde desenhar. Sem eles, no cursor, com a
--   largura disponível — que é o normal, na barra de cima. COM eles, a
--   onda é desenhada onde o chamador mandar: é assim que ela vai para o
--   topo da coluna das faixas quando elas estão ao lado do painel.
--- Onde uma ação DESTE instante seria escrita.
--
--  Gravando, o que se escreve não vai na posição do playhead: vai antes
--  dela, descontados o atraso de saída do áudio, meio quadro e o ajuste
--  manual. O motivo é bom — o som que você ouviu no instante do clique
--  já era passado, e é a ele que você reagiu. Mas a barra continuava
--  sendo desenhada no playhead cru, então o bloco aparecia sempre atrás
--  dela: "não é gravado onde a barra está naquele exato momento".
--
--  Desenhar a barra AQUI resolve os dois lados de uma vez. Ela passa a
--  marcar onde o próximo comando cai — e, por ser o mesmo desconto,
--  passa a andar junto com o som que se ouve, que é onde o playhead cru
--  nunca esteve.
local function posicaoDeEscrita()
  local pos = Transport.position()
  if not recording then return pos end
  local desconto = Timeline.outputLatency() + Timeline.frameCompensation
                   + (latency or 0)
  return math.max(0, pos - desconto)
end

--- @param xF, yF, larguraF  ver acima.
local function drawTimeline(xF, yF, larguraF)
  -- DUAS FAIXAS, e é a mudança que importa aqui: uma régua com fundo
  -- próprio em cima, a onda embaixo.
  --
  -- Antes era uma faixa só, com os tempos escritos POR CIMA da forma de
  -- onda em cinza escuro — sobre a onda, na prática eles sumiam. Numa
  -- faixa só deles, com contraste, voltam a ser legíveis sem competir
  -- com o desenho do áudio.
  local ALTURA_REGUA = 18
  local ALTURA_ONDA  = 40
  local ALTURA = ALTURA_REGUA + ALTURA_ONDA

  local from, to = vistaDaMusica()
  local duracao = to - from
  if duracao <= 0 then return end

  local largura = larguraF or ImGui.GetContentRegionAvail(ctx)
  if largura < 80 then return end

  local x0, y0
  if xF then x0, y0 = xF, yF
  else x0, y0 = ImGui.GetCursorScreenPos(ctx) end
  x0, y0 = math.floor(x0), math.floor(y0)
  largura = math.floor(largura)
  local dl = ImGui.GetWindowDrawList(ctx)

  local yOnda = y0 + ALTURA_REGUA

  -- Gravando, a faixa inteira avermelha — mesmo código de cor da
  -- pastilha e da barra de título, pra o estado ser o mesmo em toda a
  -- interface.
  local corRegua  = recording and 0x1F1518FF or 0x1A1D23FF
  local corLinha  = recording and 0x3A2226FF or 0x22252CFF
  local corTocado = recording and Theme.UI.rec or Theme.UI.accent
  local corCursor = recording and Theme.UI.rec or 0x33DD99FF

  ImGui.DrawList_AddRectFilled(dl, x0, y0, x0 + largura, y0 + ALTURA,
    Theme.UI.bg, 4)
  ImGui.DrawList_AddRectFilled(dl, x0, y0, x0 + largura, yOnda, corRegua, 4)
  ImGui.DrawList_AddLine(dl, x0, yOnda, x0 + largura, yOnda, corLinha, 1)

  local pos = posicaoDeEscrita()
  local pxCursor = nil
  if pos >= from and pos <= to then
    pxCursor = math.floor(x0 + (pos - from) / duracao * largura)
  end

  -- Forma de onda. A leitura é cara, então usa o cache por região.
  local peaks = Waveform.read(from, to)
  local meio = yOnda + ALTURA_ONDA * 0.5
  if peaks then
    -- Reamostra o que está em memória para a largura atual: uma coluna
    -- por pixel, sem reler o áudio.
    local n = math.max(1, largura)
    local total = #peaks
    for i = 1, n do
      local px = x0 + (i - 1)
      local p = peaks[math.max(1, math.min(total,
                  math.floor((i - 1) / n * total) + 1))]
      local alto = math.max(math.abs(p.max), math.abs(p.min))
      if alto > 0.002 then
        local h = math.min(1, alto) * (ALTURA_ONDA * 0.44)
        -- O trecho JÁ TOCADO em destaque, o resto apagado: dá a noção
        -- de quanto da música já passou sem precisar caçar o cursor.
        local cor = (pxCursor and px <= pxCursor) and corTocado or 0x39414FFF
        ImGui.DrawList_AddLine(dl, px, meio - h, px, meio + h, cor, 1)
      end
    end
  else
    ImGui.DrawList_AddLine(dl, x0, meio, x0 + largura, meio, 0x2A2F3AFF, 1)
  end

  -- Marcas de tempo: risco curto na régua, risco bem apagado descendo
  -- pela onda (só pra guiar o olho, sem cortar o desenho do áudio).
  local passo = 10
  if duracao > 300 then passo = 60 elseif duracao > 120 then passo = 30 end
  local t = math.ceil(from / passo) * passo
  while t < to do
    local px = math.floor(x0 + (t - from) / duracao * largura)
    ImGui.DrawList_AddLine(dl, px, y0 + 11, px, yOnda, 0x3A4150FF, 1)
    ImGui.DrawList_AddLine(dl, px, yOnda + 1, px, yOnda + ALTURA_ONDA,
      0x1E2129FF, 1)
    ImGui.DrawList_AddText(dl, px + 4, y0 + 3, 0x9199A6FF,
                           Transport.formatTime(t))
    t = t + passo
  end

  -- Cursor, com pegador no topo — o triângulo mostra que dá pra clicar
  -- ali pra navegar. Base larga de propósito: triângulo fino é a forma
  -- que a suavização do ImGui estraga (ver PROJECT_CONTEXT.md).
  if pxCursor then
    ImGui.DrawList_AddLine(dl, pxCursor, y0, pxCursor, y0 + ALTURA, corCursor, 2)
    ImGui.DrawList_AddTriangleFilled(dl,
      pxCursor - 5, y0, pxCursor + 5, y0, pxCursor, y0 + 7, corCursor)
  end

  -- Clique e ARRASTO navegam, parado ou tocando — mas NÃO gravando.
  --
  -- O destino é lembrado entre quadros porque o fim do arrasto precisa
  -- ser tratado no quadro em que o mouse é SOLTO, quando IsItemActive
  -- já voltou a ser falso e a posição do mouse não vale mais.
  ImGui.SetCursorScreenPos(ctx, x0, y0)
  ImGui.InvisibleButton(ctx, '##timeline', largura, ALTURA)

  -- A RODA SOBRE A ONDA APROXIMA E AFASTA.
  --
  -- A vista é a MESMA da lista de programação — as duas desenham o mesmo
  -- trecho da música, uma alinhada com a outra. Só que o zoom só
  -- respondia com o ponteiro sobre a lista, e a onda é justamente onde
  -- se olha para escolher o trecho: era preciso mirar noutro lugar para
  -- aproximar aquilo que se está olhando.
  --
  -- Em torno do instante SOB O MOUSE, como na lista: o ponto apontado
  -- fica onde está e o resto se aproxima dele.
  if ImGui.IsItemHovered(ctx) and ImGui.GetMouseWheel then
    local roda = ImGui.GetMouseWheel(ctx)
    if roda and roda ~= 0 then
      local mxOnda = ImGui.GetMousePos(ctx)
      local frac = (mxOnda - x0) / math.max(1, largura)
      if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
      zoomHorizontal(roda, opcoes.zoomNoMouse and (from + frac * duracao)
                           or Transport.position())
    end
  end

  if recording then
    -- Recusa explicada, não silenciosa: um clique que não faz nada e
    -- não diz por quê parece defeito.
    if ImGui.IsItemHovered(ctx) then
      dicaSe(
        'Durante a gravação o cursor não pode ser movido.\n'
        .. 'Pare o REC para navegar pela música.')
    end
    saltoEmCurso = false
    return
  end

  local ativo = ImGui.IsItemActive(ctx)
  if ativo then
    local mx = ImGui.GetMousePos(ctx)
    local frac = (mx - x0) / largura
    if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
    saltoDestino = from + frac * duracao
    saltarPara(saltoDestino, true)
  elseif saltoEmCurso then
    saltarPara(saltoDestino or Transport.position(), false)
  end
end

-- ----------------------------------------- faixas de programação

--- O modificador está pressionado AGORA? ('Ctrl' ou 'Shift')
--
--  Pelas teclas FÍSICAS, não pela flag de modificador: a flag nem sempre
--  é aceita por IsKeyDown conforme a geração do ReaImGui instalada, e
--  falhando em silêncio (pcall -> false) o gesto com modificador vira o
--  gesto sem ele — que aqui é a diferença entre preencher a música e
--  apagar a nota.
--
--  UMA função para os dois, e não uma por tecla, porque este arquivo
--  vive raspando o teto de 200 locais do Lua (ver test_integridade).
local function modAgora(qual)
  if not ImGui.IsKeyDown then return false end
  for _, lado in ipairs({ 'Left', 'Right' }) do
    local k = Compat.const(ImGui, 'Key_' .. lado .. qual, nil)
    if k and k ~= 0 then
      local ok, down = pcall(ImGui.IsKeyDown, ctx, k)
      if ok and down then return true end
    end
  end
  return false
end

--- Onde a programação da música começa: depois da célula do release, se
--  houver uma. Ver Timeline.afterReleaseTime.
local function pontoDeAbertura()
  if not region then return 0 end
  local rel = session and Session.findRelease(session)
  local pitchRel
  for _, cmd in ipairs(rel and rel.commands or {}) do
    if (cmd.status & 0xF0) == 0x90 then pitchRel = cmd.data1 break end
  end
  local depois = pitchRel
    and Timeline.afterReleaseTime(region.startTime, pitchRel)
  -- Meia célula ADIANTE do release é onde a leitura cai; a nota tem de
  -- começar na fronteira, não no meio dela. Ver Recorder.openSong.
  if depois then
    local grade = Timeline.qnToTime(
      Timeline.timeToQN(region.startTime) + Timeline.projectGrid())
      - region.startTime
    return depois - grade * 0.5
  end
  return region.startTime
end

--- Confirmação desenhada no estilo da janela, por cima de tudo.
--
--  A caixa do sistema (reaper.MB) destoa de uma interface inteira
--  desenhada à mão — e abre FORA da janela, às vezes atrás dela, o que
--  numa janela sempre-no-topo é pior que feio: a confirmação some.
--
--  Modal de verdade: enquanto houver uma pendente, nada atrás responde
--  ao mouse. Uma confirmação que dá para ignorar clicando ao lado não é
--  confirmação.
local function drawConfirmacao(px, py, pw, ph)
  if not confirmar then return end
  if not px or not pw or pw <= 0 or not ph or ph <= 0 then return end

  -- DENTRO DE UM FILHO, como o painel de configurações faz.
  --
  -- Desenhar na DrawList da janela-mãe não basta: o painel do .form é um
  -- FILHO (BeginChild 'canvas'), e o conteúdo de um filho é desenhado
  -- por cima do que a mãe põe na lista dela, mesmo que a mãe desenhe
  -- depois. Por isso a confirmação aparecia atrás de tudo.
  --
  -- A técnica certa já estava neste arquivo, em drawSettingsPanel — e eu
  -- não a usei.
  ImGui.SetCursorScreenPos(ctx, px, py)
  if not ImGui.BeginChild(ctx, '##confirmarVeu', pw, ph) then return end

  local dl = ImGui.GetWindowDrawList(ctx)
  -- Véu escuro sobre a janela toda: mostra que o resto está suspenso.
  ImGui.DrawList_AddRectFilled(dl, px, py, px + pw, py + ph, 0x0A0C10E0)

  -- Zona que engole os cliques fora do cartão: modal de verdade. Sem
  -- ela, clicar ao lado acionaria o que estivesse atrás do véu.
  --
  -- E ELA CEDE A VEZ AOS BOTÕES. No ImGui, entre dois itens sobrepostos
  -- quem fica com o mouse é o PRIMEIRO submetido — esta zona cobre o
  -- cartão inteiro e engolia os cliques em Apagar e Cancelar, que é
  -- exatamente o "não acontece nada" relatado. Mesmo defeito que a faixa
  -- de programação teve, no mesmo dia.
  ImGui.SetCursorScreenPos(ctx, px, py)
  local cedeVez = Compat.get(ImGui, 'SetNextItemAllowOverlap')
  if cedeVez then pcall(cedeVez, ctx) end
  ImGui.InvisibleButton(ctx, '##foraDaConfirmacao',
                        math.max(1, pw - 18), math.max(1, ph - 14))
  if not cedeVez then
    local antiga = Compat.get(ImGui, 'SetItemAllowOverlap')
    if antiga then pcall(antiga, ctx) end
  end

  -- O CARTÃO SE MEDE PELO TEXTO. Largura fixa cortava o nome da música,
  -- que é justamente o que diz O QUE vai ser apagado — a informação sem
  -- a qual a confirmação não confirma nada.
  local largo = ImGui.CalcTextSize(ctx, confirmar.titulo)
  for linha in (confirmar.texto .. '\n'):gmatch('([^\n]*)\n') do
    local w = ImGui.CalcTextSize(ctx, linha)
    if w > largo then largo = w end
  end

  local nLinhas = 0
  for _ in (confirmar.texto .. '\n'):gmatch('([^\n]*)\n') do
    nLinhas = nLinhas + 1
  end

  local W = math.floor(math.max(380, math.min(pw - 40, largo + 36)))
  local H = math.floor(94 + nLinhas * 16)
  local cx = math.floor(px + (pw - W) * 0.5)
  local cy = math.floor(py + (ph - H) * 0.35)

  ImGui.DrawList_AddRectFilled(dl, cx, cy, cx + W, cy + H, Theme.UI.panel, 8)
  ImGui.DrawList_AddRect(dl, cx, cy, cx + W, cy + H, 0x3A4150FF, 8, 0, 1)
  -- Faixa vermelha no topo: isto joga trabalho fora.
  ImGui.DrawList_AddRectFilled(dl, cx, cy, cx + W, cy + 3, Theme.UI.rec, 3)

  ImGui.SetCursorScreenPos(ctx, cx + 18, cy + 18)
  ImGui.TextColored(ctx, Theme.UI.text, confirmar.titulo)

  local y = cy + 44
  for linha in (confirmar.texto .. '\n'):gmatch('([^\n]*)\n') do
    ImGui.SetCursorScreenPos(ctx, cx + 18, y)
    ImGui.TextColored(ctx, Theme.UI.textDim, linha)
    y = y + 16
  end

  local function botao(id, rotulo, bx, perigo)
    local bw, bh = 104, 28
    local by = cy + H - bh - 16
    ImGui.SetCursorScreenPos(ctx, bx, by)
    ImGui.InvisibleButton(ctx, id, bw, bh)
    local clicou = ImGui.IsItemClicked(ctx)
    local sobre = ImGui.IsItemHovered(ctx)
    local fundo = perigo
      and (sobre and Theme.UI.recHover or Theme.UI.rec)
      or  (sobre and Theme.UI.panelHover or Theme.UI.panelActive)
    ImGui.DrawList_AddRectFilled(dl, bx, by, bx + bw, by + bh, fundo, 5)
    local tw = ImGui.CalcTextSize(ctx, rotulo)
    ImGui.SetCursorScreenPos(ctx, bx + (bw - tw) * 0.5, by + 6)
    ImGui.TextColored(ctx, 0xFFFFFFFF, rotulo)
    return clicou
  end

  local cancelou = botao('##confCancelar', 'Cancelar', cx + W - 226, false)
  local aceitou  = botao('##confOk', confirmar.rotulo, cx + W - 118, true)

  -- O EndChild TEM DE ACONTECER, aconteça o que acontecer com os botões.
  -- Um `return` no meio deixaria o filho aberto e o ImGui perderia o
  -- equilíbrio Begin/End — o sintoma é a janela inteira desaparecer.
  ImGui.EndChild(ctx)

  if cancelou then
    confirmar = nil
  elseif aceitou then
    local acao = confirmar.acao
    confirmar = nil
    if acao then acao() end
  end
end

--- Junta um bloco com o SEGUINTE do mesmo controle.
--
--  Dois trechos separados do mesmo comando viram um só, cobrindo o vão
--  entre eles. É o que se quer depois de regravar em pedaços: a luz
--  ficava piscando no vão sem que ninguém tivesse pedido.
--
--  O DESLIGAMENTO DO PRIMEIRO SOME e o do segundo fica. É o único
--  resultado coerente: o pulso do primeiro apagaria a luz no meio do
--  trecho novo, que é exatamente o que a junção veio desfazer.
--
--  @return boolean juntou?
local function juntarBlocos(linha, bloco)
  if not linha or not bloco or linha.tipo ~= 'botao' then return false end

  local seguinte
  for _, b in ipairs(linha.blocos) do
    if b.t0 > bloco.t0 and (not seguinte or b.t0 < seguinte.t0) then
      seguinte = b
    end
  end
  if not seguinte then
    log(('%s: não há trecho seguinte para juntar'):format(linha.nome))
    return false
  end

  -- SE UM RIVAL OCUPA O VÃO, NÃO DÁ PARA JUNTAR.
  --
  -- Aqui a recusa é a resposta certa, não um limite a aplicar em
  -- silêncio: o vão não está vazio — é outro controle do mesmo grupo que
  -- está tocando ali. Juntar por cima dele produziria dois comandos
  -- exclusivos ao mesmo tempo, e a tela passaria a mostrar algo que a
  -- reprodução não faz.
  local limite = Lanes.limiteAte(Lanes.rivais(faixas.linhas, linha),
                                 bloco.t0, seguinte.t1)
  if limite < seguinte.t1 then
    log(('%s: não juntei — um controle do mesmo grupo entra em %s')
      :format(linha.nome, Transport.formatTime(limite)))
    return false
  end

  local ok

  Timeline.editar('LumiBridge: juntar notas', function()
  if bloco.fecho then Timeline.deleteNoteAt(linha.pitch, bloco.fecho.t0) end
  Timeline.deleteNoteAt(linha.pitch, seguinte.t0)
  ok = Timeline.setNoteSpan(linha.pitch, bloco.t0, bloco.t0, seguinte.t1)
  end)

  log(ok and ('%s: juntado %s → %s'):format(linha.nome,
        Transport.formatTime(bloco.t0), Transport.formatTime(seguinte.t1))
      or 'não juntei: a nota não está mais onde estava')
  faixas.at = 0
  return ok
end

--- Relê os eventos da música e remonta as linhas, no máximo 4x/s.
--
--  Não a cada quadro: montar as linhas percorre todos os eventos da
--  região, e a faixa fica aberta o tempo todo. Quatro por segundo é
--  imperceptível para quem edita e um oitavo do trabalho.
--
--  A releitura é FORÇADA depois de toda edição nossa, senão o bloco
--  arrastado voltaria ao lugar antigo por até um quarto de segundo — o
--  bastante para parecer que o arrasto não pegou.
--- @param forcado  refaz mesmo que nada tenha mudado. É o que os
--   `faixas.at = 0` espalhados pelo arquivo querem dizer: "esqueça o que
--   está aí". Sem isso, trocar a cor de uma faixa ou mostrar todos não
--   apareceria — a assinatura abaixo não muda com essas coisas.
local function remontarFaixas(agora, forcado)
  if not (layout and session and region) then faixas.linhas = {} return end
  faixas.at = (agora or 0) + 0.25

  -- SÓ REMONTA SE ALGO MUDOU.
  --
  -- Montar as linhas percorre todos os eventos da música e ordena os
  -- blocos de cento e poucos controles — uns quatro milissegundos. Feito
  -- quatro vezes por segundo sobre uma música que não mudou, é um soluço
  -- de 4 ms oito por cento do tempo, e é assim que ele aparece: não como
  -- lentidão, como PULADA.
  --
  -- O carimbo da timeline muda a cada escrita, inclusive a cada quadro
  -- de gravação — durante o REC isto não economiza nada, e é o certo:
  -- ali as notas estão de fato crescendo.
  if not forcado then
    local assinatura = ('%d|%s|%s|%s|%s'):format(
      Timeline.revision(), tostring(region.startTime),
      tostring(region.endTime), tostring(faixas.todos),
      tostring(faixas.semCC))
    if faixas.assinatura == assinatura then return end
    faixas.assinatura = assinatura
  else
    faixas.assinatura = nil
  end

  faixas.remontagens = (faixas.remontagens or 0) + 1

  local rel = Session.findRelease(session)
  local celula = Timeline.qnToTime(
    Timeline.timeToQN(region.startTime) + Timeline.projectGrid())
    - region.startTime

  local eventos = Timeline.eventsIn(region.startTime, region.endTime)
  faixas.linhas, faixas.escondidas, faixas.nomesOcultos = Lanes.build(layout, session, eventos,
    faixas.todos, {
      inicio = region.startTime,
      celula = celula,
      releaseTag = rel and rel.tag or nil,
      semCC = faixas.semCC,
      cores = faixas.cores,
      grupoDe = faixas.grupoDe,
    })
end

--- Traz a janela para a frente, se o SWS estiver disponível.
--
--  Opcional de propósito: sem ele o LumiBridge continua funcionando
--  igual, só não pula na frente do REAPER quando a ação é executada
--  com a janela já aberta atrás.
local function acharJanelaPropria()
  if not reaper.BR_Win32_FindWindowEx then return nil end
  local ok, hwnd = pcall(reaper.BR_Win32_FindWindowEx,
    '0', '0', '', Version.NOME, false, true)
  if ok then return hwnd end
  return nil
end

--- Desenha as faixas de programação. Devolve a altura ocupada.
--
--  UMA LINHA POR CONTROLE, com o nome e a cor do .form, alinhada à mesma
--  régua da forma de onda logo acima — é o alinhamento vertical que
--  responde "caiu no lugar certo?" sem sair da tela.
--- @param larguraForcada  presente = modo COLUNA, ao lado do painel: a
--   largura vem de fora e as faixas usam a altura toda, com a onda no
--   topo. Ausente = modo empilhado, largura toda e altura escolhida.
local function drawFaixas(alturaDisponivel, larguraForcada)
  if not faixas.abertas then return 0 end

  -- SEM MÚSICA NÃO HÁ FAIXA — e as da música anterior têm de sair da
  -- tela. Só sair mais cedo deixaria as linhas antigas desenhadas, e
  -- elas parecem programação DESTA música: quem confia nisso apaga um
  -- bloco de outra região achando que está mexendo nesta.
  if not region then faixas.linhas = {} faixas.sel = nil return 0 end

  -- Trocou de música? Remonta já, sem esperar o intervalo. O que se vê
  -- na tela precisa ser o que está embaixo do cursor.
  if faixas.regiao ~= region.startTime then
    faixas.regiao = region.startTime
    faixas.at = 0
    faixas.sel = nil
  end

  local CABECALHO = 22
  -- LARGURA DA COLUNA DE NOMES, ajustável arrastando a divisória.
  --
  -- Fixa em 112px, nomes como "STAR PAIR ADV" e "FIXA CIMA LEQUE"
  -- ficavam cortados — e o nome é a única coisa que identifica a linha.
  -- Cada .form batiza os controles do seu jeito, então não existe número
  -- certo para todos: quem sabe é quem está olhando.
  local GUTTER = faixas.gutter or 112
  local ALTURA_BOTAO = 18
  local ALTURA_FADER = 34
  local PEGA = 5

  -- DURANTE O ARRASTO, NÃO REMONTA.
  --
  -- A remontagem troca a tabela de linhas inteira, e o arrasto guarda
  -- uma referência ao bloco que está sendo puxado. Remontando no meio do
  -- gesto, essa referência passa a apontar para um bloco órfão: a prévia
  -- continuava sendo escrita nele, enquanto a tela desenhava o bloco
  -- novo, parado no lugar antigo. O sintoma é o bloco tremendo e
  -- voltando sozinho quatro vezes por segundo.
  -- NEM DURANTE O ARRASTO DE UM PONTO, pelo mesmo motivo do arrasto de
  -- bloco: a remontagem troca a tabela de linhas inteira, e o arrasto
  -- guarda uma referência ao ponto puxado. Remontando no meio do gesto
  -- essa referência fica órfã — a prévia continua sendo escrita nela
  -- enquanto a tela desenha o ponto novo, parado no lugar antigo. O
  -- sintoma é o ponto voltando sozinho quatro vezes por segundo, que
  -- parece um encaixe em grade mas não é: é o gesto sendo desfeito.
  --
  -- Corrigi isso para os blocos e não estendi aos pontos. Duas coisas
  -- com o mesmo problema pedem a mesma guarda, e meia correção não é
  -- correção.
  local agora = reaper.time_precise and reaper.time_precise() or 0

  -- AS LARGURAS E ALTURAS AJUSTADAS À MÃO TÊM MEMÓRIA.
  --
  -- A coluna de nomes, a divisória do modo em coluna e a altura do modo
  -- empilhado eram esquecidas ao fechar. Cada Tela Personalizada batiza
  -- os controles do seu jeito e cada monitor tem um tamanho, então esse
  -- ajuste é feito uma vez e vale para sempre — reencontrá-lo no padrão
  -- a cada abertura é refazer o mesmo trabalho todo dia.
  --
  -- Meio segundo depois do último arrasto, e não a cada quadro: gravar
  -- ExtState enquanto a mão ainda se move é trabalho por nada.
  if faixas.salvarEm and agora >= faixas.salvarEm then
    faixas.salvarEm = nil
    reaper.SetExtState(EXT_SECTION, 'faixas_medidas',
      ('%d %d %d'):format(math.floor(faixas.gutter or 112),
                          math.floor(faixas.largura or 0),
                          math.floor(faixas.altura or 150)), true)
  end

  if agora >= faixas.at and not faixas.arraste and not faixas.arrastePonto then
    -- `faixas.at = 0` é como o resto do arquivo pede uma remontagem
    -- imediata — trocar de música, mudar cor, ligar "todos". Isso é o
    -- FORÇADO: passa por cima da assinatura.
    remontarFaixas(agora, faixas.at == 0)
  end

  local aoLado = larguraForcada ~= nil
  local largura = larguraForcada or ImGui.GetContentRegionAvail(ctx)
  if largura < 200 then return 0 end

  -- A ONDA SÓ OCUPA ALTURA NO MODO COLUNA — no empilhado ela fica lá em
  -- cima, na barra, e não sai daqui.
  local ONDA = aoLado and 58 or 0

  local teto = alturaDisponivel - CABECALHO - PEGA - 40
  local corpo
  if aoLado then
    -- COLUNA: a altura toda, sem pega. Quem divide a tela aqui é a
    -- divisória VERTICAL, desenhada por quem chamou.
    corpo = alturaDisponivel - CABECALHO - ONDA - 1
  elseif faixas.inteira then
    -- INTEIRA USA A ALTURA TODA, e sobrava uma tira morta embaixo.
    --
    -- Descontava a pega (que não existe mais neste modo) e ainda passava
    -- pelo teto, que reserva 40px para o .form nunca ser empurrado para
    -- fora da janela. Só que em "inteira" o .form nem está na tela: eram
    -- 45 pixels guardados para nada, e apareciam como uma faixa vazia no
    -- rodapé com a última linha cortada logo acima.
    corpo = alturaDisponivel - CABECALHO - 1
  else
    -- A altura escolhida, sempre limitada ao que existe, para a faixa
    -- nunca empurrar o .form para fora da janela.
    corpo = faixas.altura
    if corpo > teto then corpo = teto end
  end
  if corpo < 40 then corpo = 40 end

  local x0, y0 = ImGui.GetCursorScreenPos(ctx)
  x0, y0 = math.floor(x0), math.floor(y0)
  local dl = ImGui.GetWindowDrawList(ctx)

  -- ---------------------------------------------------- cabeçalho
  ImGui.DrawList_AddRectFilled(dl, x0, y0, x0 + largura, y0 + CABECALHO,
                               Theme.UI.panel)
  ImGui.DrawList_AddLine(dl, x0, y0, x0 + largura, y0, 0x2A2F3AFF, 1)

  ImGui.SetCursorScreenPos(ctx, x0 + 8, y0 + 4)
  -- O NOME DA COISA, EM PRIMEIRO PLANO.
  --
  -- Era caixa-alta num cinza apagado — o tratamento de rótulo secundário,
  -- daqueles que nomeiam um grupo dentro de um formulário. Só que este é
  -- o nome de uma das duas metades da janela, e estava com menos
  -- presença do que a contagem ao lado. Agora é texto claro em tamanho
  -- normal, e a contagem é que fica em segundo plano.
  ImGui.TextColored(ctx, Theme.UI.text, 'Programação MIDI')
  ImGui.SameLine(ctx)
  -- DIZ QUANTAS FICARAM DE FORA, e não só quantas entraram. Sem isso a
  -- diferença entre o que está na tela e o que existe na música fica
  -- sem explicação — e "sumiu uma linha" é a leitura natural.
  local textoConta = ('   %d controles%s'):format(#faixas.linhas,
    (faixas.escondidas or 0) > 0
      and ('  ·  %d ocultos'):format(faixas.escondidas)
      or '')
  ImGui.TextColored(ctx, 0x5F6672FF, textoConta)

  -- QUAIS ESTÃO OCULTOS, passando o mouse na contagem.
  --
  -- "6 ocultos" responde quantos e não responde quais, e o número muda
  -- com a música: é a única informação da tela que não tem outro caminho
  -- — os controles ocultos, por definição, não estão em lugar nenhum
  -- para serem lidos.
  --
  -- Por isso esta NÃO passa pelo interruptor de dicas. As outras
  -- repetem, em palavras, o que um rótulo ou um ícone já diz; desligá-las
  -- não esconde nada. Esta é o próprio dado.
  if (faixas.escondidas or 0) > 0 and ImGui.IsItemHovered
     and ImGui.IsItemHovered(ctx) and faixas.nomesOcultos then
    ImGui.SetTooltip(ctx, 'Ocultos porque só têm o que o preparo escreveu:\n\n'
      .. table.concat(faixas.nomesOcultos, '\n'))
  end

  -- BOTÕES DO CABEÇALHO, DA DIREITA PARA A ESQUERDA.
  --
  -- Cada um tem a largura do SEU texto, medida na hora. Com largura fixa
  -- eles se sobrepunham — "mostrar todos" não cabe nos mesmos 62px de
  -- "fechar", e o texto invadia o botão vizinho ("mostrar todosinteira"
  -- na tela).
  --
  -- E o clique é lido LOGO APÓS o InvisibleButton, antes de desenhar o
  -- texto. IsItemClicked responde sobre o ÚLTIMO item criado, e lido
  -- depois do TextColored ele respondia sobre o texto — que não é
  -- clicável. Era por isso que nenhum dos três funcionava.
  local xDireita = x0 + largura - 8

  --
  -- RÓTULO FIXO, ESTADO NA COR — os dois trocavam de texto a cada
  -- clique ("inteira" virava "reduzir", "mostrar todos" virava "só os
  -- usados"). Isso custava três coisas de uma vez: o botão mudava de
  -- largura, os vizinhos andavam de lugar e o alvo fugia do mouse; o
  -- rótulo passava a dizer o que ACONTECERIA em vez do que ESTÁ, e as
  -- duas leituras se confundem num relance; e não dava para ver o
  -- estado sem parar para interpretar a frase. Agora o texto não muda e
  -- o estado é o aceso, igual aos botões da barra de transporte.
  --  @param desenhar  função(dl, cx, cy, cor) que pinta um ícone no
  --                   lugar do texto. Com ela o botão tem largura fixa;
  --                   sem ela, a do próprio texto.
  local function botaoCabecalho(id, texto, dicaTexto, aceso, desenhar)
    local w = desenhar and 26 or (ImGui.CalcTextSize(ctx, texto) + 16)
    local x = xDireita - w
    xDireita = x - 6

    ImGui.SetCursorScreenPos(ctx, x, y0 + 2)
    ImGui.InvisibleButton(ctx, id, w, CABECALHO - 4)
    local clicou = ImGui.IsItemClicked(ctx)
    local sobre  = ImGui.IsItemHovered(ctx)

    local fundo = aceso and (sobre and 0x3D8BFD55 or 0x3D8BFD33)
                  or (sobre and Theme.UI.panelHover or nil)
    if fundo then
      ImGui.DrawList_AddRectFilled(dl, x, y0 + 2, x + w, y0 + CABECALHO - 2,
                                   fundo, 3)
    end
    if sobre and dicaTexto then dicaSe( dicaTexto) end

    local cor = aceso and Theme.UI.accentHover
                or (sobre and Theme.UI.text or Theme.UI.textDim)
    if desenhar then
      desenhar(dl, x + w * 0.5, y0 + CABECALHO * 0.5, cor)
    else
      ImGui.SetCursorScreenPos(ctx, x + 8, y0 + 4)
      ImGui.TextColored(ctx, cor, texto)
    end
    return clicou
  end

  -- O "FECHAR" SAIU. Ele fazia o mesmo que o botão das faixas na barra
  -- de transporte, que é por onde se liga — e um segundo lugar para
  -- desligar só multiplica onde procurar quando se quer de volta.

  -- COMO DIVIDIR A TELA: três ícones, e o desenho é a resposta.
  --
  -- Passou por quatro desenhos até aqui. Dois interruptores soltos
  -- escondiam a regra de que ligar um desligava o outro; um segmentado
  -- de palavras mostrava a exclusividade mas continuou confuso, porque o
  -- problema eram AS PALAVRAS — "ao lado" não diz ao lado de quê; um
  -- menu com frases inteiras resolveu o texto e ficou frouxo, porque
  -- texto miúdo numa tira de 22px parece frouxo ao lado de uma barra de
  -- botões de 34.
  --
  -- O que sobrou é o que a escolha sempre foi: uma escolha de LUGAR. Um
  -- retângulo com a parte que a Programação MIDI ocupa preenchida diz
  -- isso sem uma palavra, no mesmo tamanho fixo dos outros ícones do
  -- cabeçalho, e a exclusividade fica óbvia porque só um acende.
  do
    local modoAtual = faixas.inteira and 3 or (faixas.lado and 2 or 1)
    local dicas = {
      'Tela Personalizada em cima, Programação MIDI embaixo.\n\n'
      .. 'A Tela encolhe para caber na altura que sobra.',
      'Tela Personalizada e Programação MIDI lado a lado.\n\n'
      .. 'A Tela fica com a altura toda e a programação ganha uma\n'
      .. 'coluna — muitas mais linhas de uma vez. A divisória entre\n'
      .. 'as duas é arrastável.',
      'Só a Programação MIDI, sem a Tela Personalizada.\n\n'
      .. 'A lista ocupa a janela inteira.',
    }
    -- DE TRÁS PARA A FRENTE, porque o cabeçalho é desenhado da direita
    -- para a esquerda: assim os três aparecem na ordem 1, 2, 3.
    for i = 3, 1, -1 do
      if botaoCabecalho('##faixasModo' .. i, nil, dicas[i], i == modoAtual,
          function(dl2, cx, cy, cor)
            desenharLayout(dl2, cx - 7, cy - 7, 14, i, cor)
          end) then
        faixas.lado    = (i == 2)
        faixas.inteira = (i == 3)
        reaper.SetExtState(EXT_SECTION, 'faixas_lado',
                           faixas.lado and '1' or '0', true)
        encaixe.w = 0
      end
    end

    -- UM RISCO entre o layout e os filtros: um decide como a janela se
    -- divide, os outros decidem o que a lista mostra.
    ImGui.DrawList_AddLine(dl, xDireita + 1, y0 + 6,
                           xDireita + 1, y0 + CABECALHO - 6, 0x2A2F3AFF, 1)
    xDireita = xDireita - 6
  end

  -- O FILTRO é outra coisa: não é ONDE a lista fica, é O QUE ela mostra.
  -- Por isso fora do grupo, com folga entre os dois.
  -- OS CC, o outro filtro — e do mesmo jeito: aceso quer dizer
  -- escondendo. Veio da barra de transporte, onde era um botão de janela
  -- entre botões de janela; aqui é um filtro entre filtros.
  if botaoCabecalho('##faixasCC', nil,
      'Filtro: esconde as linhas de fader (CC).\n\n'
      .. 'Vale também para a área de CC do editor MIDI do REAPER —\n'
      .. 'lá depende de ele estar aberto no item certo; aqui funciona\n'
      .. 'sempre.',
      faixas.semCC,
      function(dl2, cx, cy, cor)
        -- Uma curva de automação: sobe, faz um patamar e desce.
        local pts = { { -8, 4 }, { -4, -4 }, { 0, -4 }, { 4, 3 }, { 8, 3 } }
        for k = 1, #pts - 1 do
          ImGui.DrawList_AddLine(dl2, cx + pts[k][1], cy + pts[k][2],
                                 cx + pts[k + 1][1], cy + pts[k + 1][2],
                                 cor, 1.4)
        end
        ImGui.DrawList_AddCircleFilled(dl2, cx - 4, cy - 4, 1.8, cor)
        ImGui.DrawList_AddCircleFilled(dl2, cx + 4, cy + 3, 1.8, cor)
      end) then
    -- O MESMO BOTÃO VALE PARA AS DUAS TELAS. Ter um "ocultar CC" que
    -- esconde no editor do REAPER e deixa as mesmas linhas à mostra aqui
    -- seria um botão que faz metade do que diz — e aqui é a metade que
    -- sempre funciona: no editor depende de ele estar aberto no item
    -- certo. A decisão de esconder é do usuário; o editor recebe o
    -- pedido e atende se puder.
    faixas.semCC = not faixas.semCC
    faixas.at = 0
    local okCC, erroCC = CCLanes.toggle()
    if not okCC then log('CC lanes do editor: ' .. tostring(erroCC)) end
  end

  -- O FILTRO, um funil — e ACESO quer dizer FILTRANDO.
  --
  -- O rótulo era "todos", aceso quando mostrava todos: um botão que
  -- acende para dizer "não estou escondendo nada". Um funil aceso diz o
  -- contrário e diz certo — há um filtro em ação, e por isso a lista tem
  -- menos linhas do que a música tem controles. É a convenção de
  -- qualquer planilha, e é o estado que precisa ser percebido: ver a
  -- lista curta e não saber por quê é o problema real.
  if botaoCabecalho('##faixasTodos', nil,
      'Filtro: mostra só os controles em uso nesta música.\n\n'
      .. 'Aceso, a lista esconde o que não tem nada gravado.\n'
      .. 'Apagado, mostra todos os controles da Tela Personalizada.',
      not faixas.todos,
      function(dl2, cx, cy, cor)
        -- Funil: boca larga em cima, haste curta embaixo.
        local x1, x2 = cx - 7, cx + 7
        local y1 = cy - 6
        ImGui.DrawList_AddLine(dl2, x1, y1, x2, y1, cor, 1.4)
        ImGui.DrawList_AddLine(dl2, x1, y1, cx - 1.5, cy + 1, cor, 1.4)
        ImGui.DrawList_AddLine(dl2, x2, y1, cx + 1.5, cy + 1, cor, 1.4)
        ImGui.DrawList_AddLine(dl2, cx - 1.5, cy + 1, cx - 1.5, cy + 6, cor, 1.4)
        ImGui.DrawList_AddLine(dl2, cx + 1.5, cy + 1, cx + 1.5, cy + 4.5, cor, 1.4)
        ImGui.DrawList_AddLine(dl2, cx - 1.5, cy + 6, cx + 1.5, cy + 4.5, cor, 1.4)
      end) then
    faixas.todos = not faixas.todos
    faixas.at = 0
  end


  -- SÓ SOBRARAM FILTROS AQUI. O virar-página virou ajuste (é o
  -- comportamento normal, e um botão para o normal nunca se aperta) e a
  -- lupa foi para a barra de cima, junto da onda: o zoom é da linha do
  -- tempo, e vale para as duas telas de uma vez.
  --
  -- O CONDICIONAL POR ÚLTIMO, e por isso mais à esquerda: desenhados da
  -- direita para a esquerda, um botão que vai e vem no MEIO empurraria
  -- os fixos de lugar toda vez que aparecesse. Na ponta, ele aparece e
  -- some sem mexer com ninguém.
  --
  -- E só aparece com zoom: "música toda" numa vista que já é a música
  -- toda seria um botão morto na tela o tempo todo. Com zoom ele é
  -- indispensável — sem ele, voltar exige girar a roda até o fim sem
  -- saber quando chegou.

  -- ------------------------------------------------------- corpo
  local yc = y0 + CABECALHO

  -- A ONDA NO TOPO DA COLUNA, e recuada pela largura dos nomes.
  --
  -- O recuo é o que faz a régua valer: a área de tempo das faixas começa
  -- depois da coluna de nomes, então uma onda que começasse na borda
  -- mostraria o mesmo instante 112px à esquerda do bloco gravado dele.
  if aoLado then
    drawTimeline(x0 + GUTTER, yc, largura - GUTTER)
    yc = yc + ONDA
  end

  ImGui.DrawList_AddRectFilled(dl, x0, yc, x0 + largura, yc + corpo, Theme.UI.bg)
  ImGui.DrawList_AddRectFilled(dl, x0, yc, x0 + GUTTER, yc + corpo, 0x181B21FF)

  -- TUDO O QUE VEM A SEGUIR FICA DENTRO DO CORPO.
  --
  -- A primeira linha visível quase nunca começa no topo: com a lista
  -- rolada, ela começa ACIMA e só a parte de baixo dela aparece. Sem
  -- recorte, o desenho dessa linha — o nome, o número, os blocos —
  -- transbordava para cima e caía em cima do título "PROGRAMAÇÃO" e dos
  -- botões do cabeçalho. Rolar a lista sujava o cabeçalho.
  local recortar = Compat.get(ImGui, 'DrawList_PushClipRect')
  local desrecortar = Compat.get(ImGui, 'DrawList_PopClipRect')
  if recortar and desrecortar then
    pcall(recortar, dl, x0, yc, x0 + largura, yc + corpo, true)
  else
    desrecortar = nil
  end
  ImGui.DrawList_AddLine(dl, x0 + GUTTER, yc, x0 + GUTTER, yc + corpo,
                         0x20232AFF, 1)

  local de, ate = vistaDaMusica()
  local duracao = ate - de
  if duracao <= 0 then return CABECALHO + corpo + PEGA end
  local areaW = largura - GUTTER
  local escala = duracao / math.max(1, areaW)   -- segundos por pixel

  local function xDe(t)
    local f = (t - de) / duracao
    if f < 0 then f = 0 elseif f > 1 then f = 1 end
    return x0 + GUTTER + f * areaW
  end
  local function tDe(x)
    local f = (x - (x0 + GUTTER)) / math.max(1, areaW)
    if f < 0 then f = 0 elseif f > 1 then f = 1 end
    return de + f * duracao
  end

  -- Linhas verticais nos mesmos pontos da régua da forma de onda: é o
  -- que deixa o olho seguir do áudio para o bloco sem se perder.
  for k = 1, 5 do
    local gx = math.floor(x0 + GUTTER + areaW * (k / 6))
    ImGui.DrawList_AddLine(dl, gx, yc, gx, yc + corpo, 0x1B1E25FF, 1)
  end

  -- ZONA DE CLIQUE ÚNICA para todo o corpo. Uma por bloco seria mais
  -- simples de escrever e faria a conta de acerto duas vezes — uma no
  -- ImGui e outra aqui — com duas chances de discordarem.
  ImGui.SetCursorScreenPos(ctx, x0, yc)

  -- O CORPO CEDE A VEZ AOS ITENS DE CIMA DELE.
  --
  -- No ImGui, quando dois itens se sobrepõem quem fica com o mouse é o
  -- PRIMEIRO submetido, não o último. Esta zona cobre a faixa inteira e
  -- é criada antes do nome de cada linha e da divisória da coluna — ela
  -- reivindicava o cursor e os dois nunca recebiam nada: o arrasto da
  -- divisória não funcionava e o botão direito no nome também não.
  --
  -- O nome da chamada mudou entre gerações do Dear ImGui (a nova avisa
  -- ANTES do item, a antiga marca DEPOIS), então tentamos as duas.
  local permitirSobrepor = Compat.get(ImGui, 'SetNextItemAllowOverlap')
  if permitirSobrepor then pcall(permitirSobrepor, ctx) end

  ImGui.InvisibleButton(ctx, '##faixasCorpo', largura, corpo)

  if not permitirSobrepor then
    local antiga = Compat.get(ImGui, 'SetItemAllowOverlap')
    if antiga then pcall(antiga, ctx) end
  end
  local sobreCorpo = ImGui.IsItemHovered(ctx)
  local ativoCorpo = ImGui.IsItemActive and ImGui.IsItemActive(ctx)
  local mx, my = ImGui.GetMousePos(ctx)

  -- GEOMETRIA DO QUADRO, guardada para o teste poder clicar onde o
  -- usuário clicaria. Sem isto, um teste de clique teria de recalcular à
  -- mão as constantes daqui — e passaria a concordar consigo mesmo em
  -- vez de com o desenho.
  faixas.geom = { x0 = x0, gutter = GUTTER, areaW = areaW, yc = yc,
                  corpo = corpo,
                  de = de, duracao = duracao, alturas = {} }

  -- O QUE ESTE QUADRO CUSTOU EM DESENHO, e não em tempo. O tempo que
  -- gastamos já é medido; o que faltava é o TAMANHO da lista que a gente
  -- entrega para o ReaImGui desenhar depois — é lá que o quadro se
  -- atrasa sem aparecer em nenhum cronômetro nosso.
  faixas.desenhadas = 0
  faixas.segmentos = 0
  faixas.sobNome = nil
  faixas.sobLinha = nil

  local yLinha = yc - faixas.rolagem
  local alturaTotal = 0
  local acertou = nil          -- { linha, bloco, parte } sob o mouse
  local noFader = nil          -- { linha, indice, ponto, valor } sob o mouse

  for _, linha in ipairs(faixas.linhas) do
    local h = math.floor(((linha.tipo == 'fader') and ALTURA_FADER
                          or ALTURA_BOTAO) * (faixas.escalaV or 1))
    faixas.geom.alturas[#faixas.geom.alturas + 1] = h
    alturaTotal = alturaTotal + h

    if yLinha + h > yc and yLinha < yc + corpo then
      faixas.desenhadas = faixas.desenhadas + 1
      local cor = linha.cor and Theme.rgba(linha.cor) or 0x6B7280FF
      -- O terminador é a MESMA cor, bem mais clara: pertence ao bloco,
      -- não é outro elemento. Uma cor fixa (branco) faria todos os
      -- controles terminarem igual e apagaria a leitura por cor.
      local corFecho = linha.cor and Theme.rgba(Model.shade(linha.cor, 0.65))
                       or 0xC7CDD8FF

      -- O ELEMENTO DO .FORM POR TRÁS DESTA LINHA. Pode não existir: uma
      -- linha gravada de um controle que o .form não tem mais continua
      -- valendo como rótulo do que está na música, mas não aciona nada.
      -- FADER fica de fora: o valor dele é uma posição, não um toque, e
      -- não há posição nenhuma num clique no nome.
      local elNome = (session and linha.tag and linha.tipo ~= 'fader')
                     and session.byTag[linha.tag] or nil

      -- O FADER TAMBÉM É CONTROLÁVEL PELA LISTA.
      --
      -- Ele ficava de fora porque um clique não carrega posição nenhuma,
      -- e o valor de um fader É uma posição. O gesto que carrega posição
      -- é o ARRASTO — e a roda, que anda de degrau em degrau. Os dois
      -- entram na mesma fila do .form, então grupo de fader, envio MIDI
      -- e gravação valem igual, sem uma linha de regra nova.
      local elFader = (session and linha.tag and linha.tipo == 'fader')
                      and session.byTag[linha.tag] or nil
      local valorFader = elFader
        and (Session.faderValue(session, elFader) or 0) or nil

      -- ACESO OU APAGADO, o mesmo estado do botão no .form.
      --
      -- Sem isto o nome acionava mas não RESPONDIA: apertar acendia o
      -- botão lá no painel e o nome ficava igual — e no modo "inteira",
      -- com o painel escondido, não sobrava nenhum retorno na tela. Um
      -- botão que não mostra se está ligado não é o mesmo botão.
      --
      -- A pergunta é feita ao Session, a MESMA que o ui/renderer.lua faz
      -- para pintar o botão do .form: dois jeitos de responder "está
      -- ligado?" divergiriam no primeiro caso de canto (grupo de um
      -- ativo só, página coberta) e a lista passaria a mentir.
      local ligado = elNome
        and Session.isActive(session, elNome, linha.tag) or false
      linha.ligado = ligado
      linha.momentaneo = (elNome and elNome.momentary) or false

      ImGui.DrawList_AddLine(dl, x0, yLinha + h, x0 + largura, yLinha + h,
                             0x20232AFF, 1)

      -- A INTENSIDADE DO FADER, no lugar do aceso.
      --
      -- Um fader não está ligado ou desligado: está EM ALGUM PONTO. O
      -- preenchimento diz onde, e o traço vivo marca a posição exata —
      -- de relance o comprimento já responde, e de perto o traço dá o
      -- valor. Cor da própria faixa: cada fader continua sendo
      -- reconhecível pela cor dele, aqui e nos blocos.
      if valorFader then
        local larg = math.max(0, GUTTER - 8)
        local ate = x0 + 4 + larg * valorFader
        ImGui.DrawList_AddRectFilled(dl, x0 + 4, yLinha + 1, ate,
                                     yLinha + h - 1,
                                     (cor & 0xFFFFFF00) | 0x3A, 2)
        ImGui.DrawList_AddRectFilled(dl, ate - 1, yLinha + 1, ate + 1,
                                     yLinha + h - 1, cor)
      end

      -- O ACESO PRIMEIRO, para ficar por baixo da amostra e do nome: no
      -- DrawList quem é submetido depois cobre quem veio antes.
      if ligado then
        ImGui.DrawList_AddRectFilled(dl, x0 + 2, yLinha + 1,
                                     x0 + GUTTER - 2, yLinha + h - 1,
                                     (cor & 0xFFFFFF00) | 0x44, 2)
        ImGui.DrawList_AddRectFilled(dl, x0 + 2, yLinha + 1,
                                     x0 + 4, yLinha + h - 1, cor, 1)
      end

      ImGui.DrawList_AddRectFilled(dl, x0 + 6, yLinha + 5, x0 + 13,
                                   yLinha + 12, cor, 1)

      -- O NOME É UM BOTÃO: clicar aciona o controle, como no .form.
      --
      -- Vira a terceira forma de acionar o mesmo controle (o .form, a
      -- tecla F, e agora a lista) — e a única que funciona com o painel
      -- escondido, porque no modo "inteira" os botões do .form nem estão
      -- na tela. Também é a mais direta quando se sabe o NOME do
      -- controle mas não onde ele fica no desenho.
      -- O BOTÃO PARA ANTES DA DIVISÓRIA e não sobe além do cabeçalho.
      --
      -- Ele cobria a coluna inteira, divisória inclusive. Como as linhas
      -- são submetidas ANTES dela, era o nome que ficava com o cursor
      -- naqueles pixels e a divisória quase não dava para pegar — "bem
      -- ruim de conseguir usar". Oito pixels a menos resolvem sem tirar
      -- nada de útil do nome, e são os mesmos oito que a divisória usa
      -- agora — ela deixou de invadir a área das notas.
      --
      -- E o topo é preso ao corpo: a primeira linha visível costuma
      -- começar acima dele, e um botão que sobe junto ficaria clicável
      -- por cima do cabeçalho.
      local yBotao = math.max(yLinha, yc)
      local hBotao = math.max(1, yLinha + h - yBotao)
      ImGui.SetCursorScreenPos(ctx, x0, yBotao)
      ImGui.InvisibleButton(ctx, '##faixaNome' .. tostring(linha.tag),
                            math.max(1, GUTTER - 8), hBotao)
      local sobreNome = ImGui.IsItemHovered(ctx)

      -- O BOTÃO DIREITO abre o menu desta faixa: a cor dela e — como no
      -- .form, onde o clique direito faz exatamente isso — a atribuição
      -- de uma tecla F1-F12 ao controle.
      if ImGui.IsItemClicked(ctx, 1) then
        faixas.menuCor = linha.tag
        faixas.menuNome = linha.nome
        faixas.menuEl = elNome
        ImGui.OpenPopup(ctx, 'corDaFaixa')
      end

      -- QUEM ESTÁ SOB O MOUSE na coluna de nomes. Lido aqui, dentro do
      -- laço, porque só aqui se sabe onde cada linha começa e termina —
      -- e a roda, tratada mais abaixo, precisa saber se está sobre um
      -- fader ou sobre lista para escolher o que fazer.
      if my >= yLinha and my < yLinha + h then
        if mx < x0 + GUTTER then faixas.sobNome = linha end
        -- A LINHA SOB O MOUSE, para o duplo clique saber em qual criar.
        faixas.sobLinha = linha
      end

      -- ARRASTAR O NOME DE UM FADER MOVE O FADER.
      --
      -- Para frente sobe, para trás desce, e a coluna inteira é o curso
      -- completo. Valor ABSOLUTO a partir de onde o gesto começou, e não
      -- somado quadro a quadro: somando, um gesto rápido acumularia
      -- erro e o fader não voltaria ao mesmo lugar pelo mesmo caminho.
      if elFader then
        if ImGui.IsItemActive and ImGui.IsItemActive(ctx) then
          local a = faixas.arrasteFader
          if not a or a.tag ~= linha.tag then
            a = { tag = linha.tag, x = mx, v = valorFader }
            faixas.arrasteFader = a
          end
          local curso = math.max(120, GUTTER)
          local v = a.v + (mx - a.x) / curso
          if v < 0 then v = 0 elseif v > 1 then v = 1 end
          faixas.acionar[#faixas.acionar + 1] =
            { element = elFader, kind = 'fader', value = v }
          if ImGui.SetMouseCursor then
            local c = Compat.const(ImGui, 'MouseCursor_ResizeEW', nil)
            if c then pcall(ImGui.SetMouseCursor, ctx, c) end
          end
        elseif faixas.arrasteFader
               and faixas.arrasteFader.tag == linha.tag then
          faixas.arrasteFader = nil
        end
      end

      if elNome then
        if sobreNome then
          ImGui.DrawList_AddRectFilled(dl, x0 + 2, yLinha + 1,
                                       x0 + GUTTER - 2, yLinha + h - 1,
                                       0x3D8BFD22, 2)
        end
        -- MOMENTÂNEO PRECISA DA DESCIDA E DA SUBIDA, como no .form: a
        -- diferença entre segurar e clicar é o controle inteiro. São os
        -- FLASH, STROBO e FUMAÇA — a dúzia de botões que só fazem
        -- sentido segurados.
        --
        -- A DESCIDA vem do clique NESTE item. A SUBIDA vem do botão do
        -- mouse, tratada fora do laço (ver `frame`).
        --
        -- NÃO de IsItemActive, que é como o ui/renderer.lua faz e como
        -- isto começou. Lá o botão está sozinho no canvas; aqui a zona
        -- que cobre a faixa inteira (##faixasCorpo) é submetida ANTES
        -- dos nomes, e quem fica com o "item ativo" quando duas coisas
        -- se sobrepõem é decisão do ImGui. Com a zona levando o ativo, o
        -- nome recebia a descida e no quadro seguinte já parecia solto:
        -- segurar o FLASH mandava um toque e soltava sozinho — "quando
        -- deixo clicado ele envia só um click". O CLIQUE, esse, não é
        -- disputado: basta estar sob o mouse.
        if elNome.momentary then
          if ImGui.IsItemClicked(ctx) and not faixas.segurando[linha.tag] then
            faixas.segurando[linha.tag] = true
            faixas.acionar[#faixas.acionar + 1] =
              { element = elNome, kind = 'press' }
          end
        elseif ImGui.IsItemClicked(ctx) then
          faixas.acionar[#faixas.acionar + 1] =
            { element = elNome, kind = 'click' }
        end
      end

      -- SEM DICA NO NOME, tampouco. Já não havia dica sobre os blocos —
      -- ela nascia onde a mão trabalha e cobria as linhas vizinhas. A do
      -- nome tem o mesmo defeito e é pior: o nome é onde mais se passa o
      -- mouse, porque é por ali que se aciona, se arrasta fader e se
      -- abre o menu de cor. Uma dica ali cobre justamente a lista que se
      -- está lendo.
      if false and sobreNome then
        local comoUsar = ''
        if elFader then
          comoUsar = ('%d%%\n\nArraste para os lados para mover o fader.\n'
                      .. 'Roda do mouse: sobe e desce de degrau em degrau.\n'
                      .. 'Com a tecla de um grupo segurada, os companheiros\n'
                      .. 'vão junto — igual na Tela Personalizada.\n')
                     :format(math.floor((valorFader or 0) * 100 + 0.5))
        elseif elNome then
          comoUsar = elNome.momentary
            and 'Segure: aciona enquanto estiver apertado.\n'
            or  'Clique: liga e desliga, como na Tela Personalizada.\n'
        end
        dicaSe( ('%s\n\n%sBotão direito: cor da linha e tecla F.')
          :format(linha.nome, comoUsar))
      end

      ImGui.SetCursorScreenPos(ctx, x0 + 19, yLinha + 2)
      ImGui.TextColored(ctx, ligado and 0xFFFFFFFF or Theme.UI.text,
                        linha.nome)

      -- O NÚMERO MIDI, apagado, junto do nome.
      --
      -- É a ponte com o editor do REAPER: lá se lê "59", aqui "LED
      -- DIREITA". Com os dois lado a lado, olhar uma tela e achar a
      -- linha na outra é imediato — que é o motivo de as faixas estarem
      -- na mesma ordem do editor.
      -- O CANAL, junto do número. "Em que canal isto está gravando?" não
      -- tinha resposta em lugar nenhum da tela — e cada controle da Tela
      -- Personalizada pode estar num canal diferente, então não é um
      -- número só para o programa inteiro.
      -- O CANAL JÁ VEM EM BASE 1 do Model.command, que faz o +1 sobre o
      -- nibble do status byte justamente para casar com o que o REAPER
      -- mostra. Eu somei 1 de novo aqui, e uma tela toda no canal 1
      -- aparecia como canal 2 — um erro que só se vê comparando com
      -- outra tela, e que colocaria alguém a procurar defeito no Lumikit.
      local numero = (linha.tipo == 'fader')
        and ('CC%d·%d'):format(linha.cc or 0, linha.canal or 1)
        or  ('%s·%d'):format(tostring(linha.pitch or ''), linha.canal or 1)
      local larguraNum = ImGui.CalcTextSize(ctx, numero)
      ImGui.SetCursorScreenPos(ctx, x0 + GUTTER - larguraNum - 6, yLinha + 2)
      ImGui.TextColored(ctx, 0x555C68FF, numero)

      -- O CRACHÁ DA TECLA F, como no botão do .form. Sem ele a lista
      -- ficava sendo o único lugar onde não dá para ver que aquele
      -- controle já tem uma tecla — e a tecla é a forma mais rápida de
      -- acionar as três.
      local cracha = linha.tag and state.fkeyBadge
                     and state.fkeyBadge[linha.tag]
      if cracha then
        local lc = ImGui.CalcTextSize(ctx, cracha)
        ImGui.SetCursorScreenPos(ctx,
          x0 + GUTTER - larguraNum - lc - 14, yLinha + 2)
        ImGui.TextColored(ctx, Theme.UI.accent, cracha)
      end

      if linha.tipo == 'fader' then
        -- CURVA EM RAMPA, ligando ponto a ponto — não em degrau.
        --
        -- Era um degrau: horizontal até o próximo ponto e só então
        -- vertical. Isso desenha uma coisa que o LumiBridge NÃO faz: a
        -- automação de fader é interpolada entre os pontos (ver
        -- Timeline.ccValuesAt), então uma subida gravada em três
        -- segundos aparecia como um salto seco no fim. Ver a forma
        -- errada de um gesto é pior que não ver forma nenhuma.
        --
        -- Trilhos de 0% e 100% ao fundo, para o valor ter referência: um
        -- traço no meio da faixa não diz sozinho se é 50% ou 90%.
        local yCheio = yLinha + 4
        local yZero  = yLinha + h - 4
        ImGui.DrawList_AddLine(dl, x0 + GUTTER, yCheio, x0 + largura,
                               yCheio, 0x1E2128FF, 1)
        ImGui.DrawList_AddLine(dl, x0 + GUTTER, yZero, x0 + largura,
                               yZero, 0x1E2128FF, 1)

        local function yDoValor(v)
          return yZero - (v / 127) * (yZero - yCheio)
        end

        -- A CURVA DESENHADA É A MESMA QUE A REPRODUÇÃO EXECUTA.
        --
        -- Entre dois pontos a automação não anda em linha reta: ela usa
        -- "slow start/end" — suave = t²(3-2t), a mesma conta em
        -- Timeline.ccValuesAt e em midi/cclanes.lua. Já foi desenhada
        -- como degrau e como reta, e as duas mostram um gesto que o
        -- LumiBridge não faz. Ver a forma errada é pior que não ver
        -- forma nenhuma: é decidir uma regravação por um desenho que
        -- mente.
        --
        -- OS CORTES SAEM DO TAMANHO DO TRECHO NA TELA, não de um número
        -- fixo. Ver Curve.cortes: doze pedaços num trecho de três pixels
        -- são onze linhas que ninguém vê, e numa automação densa isso
        -- vira milhares de segmentos por quadro.
        local px, py = nil, nil
        for _, p in ipairs(linha.pontos) do
          local cx, cy = xDe(p.t), yDoValor(p.valor)
          -- ANTES DO PRIMEIRO PONTO o valor já vale: o fader não nasce
          -- no primeiro ponto, ele estava naquele valor desde o começo
          -- da música. Sem este trecho a faixa parecia vazia até o
          -- primeiro movimento.
          if not px then
            ImGui.DrawList_AddLine(dl, x0 + GUTTER, cy, cx, cy, cor, 1.4)
          else
            local ax, ay = px, py
            local CORTES = Curve.cortes(cx - px, cy - py)
            faixas.segmentos = (faixas.segmentos or 0) + CORTES
            for k = 1, CORTES do
              local t = k / CORTES
              local suave = t * t * (3 - 2 * t)
              local bx = px + (cx - px) * t
              local by = py + (cy - py) * suave
              ImGui.DrawList_AddLine(dl, ax, ay, bx, by, cor, 1.4)
              ax, ay = bx, by
            end
          end
          -- SELECIONADO: círculo maior e um anel claro em volta. O
          -- tamanho sozinho não bastava — num traço fino de automação,
          -- meio pixel a mais não se vê.
          local selecionado = faixas.selCC[linha.tag]
                              and faixas.selCC[linha.tag][p.t]
          if selecionado then
            ImGui.DrawList_AddCircleFilled(dl, cx, cy, 4.2, cor)
            ImGui.DrawList_AddCircle(dl, cx, cy, 5.6, 0xFFFFFFCC, 0, 1.4)
          else
            ImGui.DrawList_AddCircleFilled(dl, cx, cy, 2.2, cor)
          end
          px, py = cx, cy
        end
        -- E DEPOIS DO ÚLTIMO ele continua valendo até o fim.
        if px then
          ImGui.DrawList_AddLine(dl, px, py, x0 + largura, py, cor, 1.4)
        end

        -- O QUE O MOUSE ALCANÇA NESTA FAIXA.
        --
        -- Calculado AQUI, dentro do laço, porque só aqui se conhece a
        -- altura desta linha e onde ficam o 0% e o 100% dela — e é disso
        -- que sai o valor sob o cursor. Fora do laço seria preciso
        -- refazer a conta, com duas chances de discordar do desenho.
        if sobreCorpo and my >= yLinha and my < yLinha + h
           and mx > x0 + GUTTER then
          local i, ponto = Lanes.hitPonto(linha, tDe(mx), escala * 6)
          local v = (yZero - my) / math.max(1, yZero - yCheio) * 127
          if v < 0 then v = 0 elseif v > 127 then v = 127 end
          noFader = { linha = linha, indice = i, ponto = ponto, valor = v,
                      yZero = yZero, yCheio = yCheio }
          if ponto then
            ImGui.DrawList_AddCircle(dl, xDe(ponto.t), yDoValor(ponto.valor),
                                     4.5, 0xFFFFFFFF, 0, 1.4)
          end
        end
      else
        for _, b in ipairs(linha.blocos) do
          local bx0, bx1 = xDe(b.t0), xDe(b.t1)
          if bx1 - bx0 < 2 then bx1 = bx0 + 2 end
          ImGui.DrawList_AddRectFilled(dl, bx0, yLinha + 3, bx1,
                                       yLinha + h - 3, cor, 2)

          -- TERMINADOR: barra clara e um pouco mais alta na borda,
          -- onde VOCÊ desligou o controle.
          --
          -- O pulso que apaga a luz é uma nota curta colada no fim (ver
          -- Lanes.dobrarFechos). Desenhá-lo como bloco separado — que é
          -- o que o editor MIDI faz — parece sujeira e exige conhecer a
          -- convenção. Como marca de fim, distingue de relance um trecho
          -- que você encerrou de um que apenas acabou: regra de grupo,
          -- fim da gravação, fim da música. Essa diferença está na
          -- gravação e não é visível em lugar nenhum hoje.
          if b.fecho then
            ImGui.DrawList_AddRectFilled(dl, bx1 - 1, yLinha + 1,
                                         bx1 + 3, yLinha + h - 1,
                                         corFecho, 1)
          end

          -- NA SELEÇÃO MÚLTIPLA, um contorno azul.
          --
          -- Diferente do branco da seleção única de propósito: uma é
          -- "este bloco é o alvo dos atalhos", a outra é "estes vão
          -- juntos". Ver as duas iguais faria perguntar qual delas o Del
          -- vai apagar.
          if Lanes.marcada(faixas.selNotas, linha.tag, b.t0) then
            -- POR FORA, e fino. Um contorno de dois pixels em cima da
            -- borda come a cor do bloco — num bloco estreito, quase todo
            -- ele vira azul e some qual controle era. Desenhado dois
            -- pixels fora, a cor do bloco fica inteira e a marca
            -- continua legível.
            ImGui.DrawList_AddRect(dl, bx0 - 3, yLinha - 1, bx1 + 3,
                                   yLinha + h + 1, Theme.UI.accent, 3, 0, 1.5)
          end

          local eSel = faixas.sel and faixas.sel.tag == linha.tag
                       and math.abs(faixas.sel.t0 - b.t0) < 0.002
          if eSel then
            ImGui.DrawList_AddRect(dl, bx0 - 1, yLinha + 2, bx1 + 1,
                                   yLinha + h - 2, 0xFFFFFFFF, 2, 0, 1.6)
            ImGui.DrawList_AddRectFilled(dl, bx0 - 2, yLinha + 4, bx0 + 2,
                                         yLinha + h - 4, 0xFFFFFFFF, 1)
            ImGui.DrawList_AddRectFilled(dl, bx1 - 2, yLinha + 4, bx1 + 2,
                                         yLinha + h - 4, 0xFFFFFFFF, 1)
          end
        end

        if sobreCorpo and my >= yLinha and my < yLinha + h and mx > x0 + GUTTER then
          local b, parte = Lanes.hit(linha, tDe(mx), escala)
          -- ENCOSTADO NA BORDA DIREITA, O FIM É O FIM.
          --
          -- Uma nota que termina no limite da vista tem a pega da borda
          -- nos últimos quatro pixels — e ali quem fica com o mouse é a
          -- moldura de redimensionar do REAPER: arrastar aumenta a
          -- janela em vez de encurtar a nota. Relatado assim, depois de
          -- a borda esquerda ter sido resolvida.
          --
          -- Nos dezesseis pixels finais, um bloco que chega até lá é
          -- tratado como pego pela ponta. Sobram uns dez pixels livres
          -- da moldura, que é o que a mão precisa. Vale também para a
          -- nota que segue ALÉM da vista: ali não havia pega nenhuma.
          if b and parte == 'meio'
             and mx > x0 + GUTTER + areaW - 16
             and b.t1 >= tDe(x0 + GUTTER + areaW - 16) then
            parte = 'fim'
          end
          if b then acertou = { linha = linha, bloco = b, parte = parte } end
        end
      end
    end

    yLinha = yLinha + h
  end

  -- ROLAGEM, com o limite calculado DEPOIS do laço: só ali se sabe a
  -- altura total. Sem o limite, a roda levaria as linhas para fora da
  -- faixa e a tela ficaria em branco sem explicação.
  -- ALTURA DE ABERTURA: cabe tudo, até quase metade da área.
  --
  -- Só aqui se sabe a altura total das linhas, então o ajuste pedido ao
  -- abrir (ver o botão da barra) é atendido neste quadro e vale a partir
  -- do próximo.
  if faixas.ajustar then
    faixas.ajustar = nil
    faixas.altura = math.max(60,
      math.min(alturaTotal + 6, math.floor(alturaDisponivel * 0.45)))
    encaixe.w = 0
  end

  -- A RODA DO MOUSE, com três destinos.
  --
  --   roda SOBRE OS NOMES  -> rolar a lista
  --   roda sobre o tempo   -> zoom HORIZONTAL, em torno do instante
  --   Ctrl + roda          -> zoom VERTICAL (altura das linhas)
  --   Shift + roda         -> rolar a lista, de qualquer lugar
  --
  -- ONDE O MOUSE ESTÁ decide, e não um modificador: a coluna de nomes é
  -- uma LISTA, e roda em cima de lista rola — é o que a mão faz sem
  -- pensar, e é o que o cabeçalho de trilha de qualquer DAW faz. Sobre o
  -- tempo continua o zoom. Agora que os nomes são botões, e que em
  -- coluna cabem dezenas de linhas de mais de cem, rolar deixou de ser
  -- exceção e voltou a ser o gesto comum.
  --
  -- O horizontal fica na roda pura porque é o gesto mais frequente:
  -- aproximar para ajustar uma borda, afastar para ver a música inteira.
  -- A rolagem, que era o uso da roda pura, passou para o Shift — com a
  -- faixa abrindo já no tamanho do conteúdo, rolar virou exceção.
  -- Fecha o recorte: daqui para baixo desenha-se o cursor, a barra de
  -- rolagem e a pega, que são do quadro inteiro e não do miolo.
  if desrecortar then pcall(desrecortar, dl) end

  local excedente = math.max(0, alturaTotal - corpo)

  -- HOVER POR RETÂNGULO, e não pelo item — foi o que quebrou a rolagem.
  --
  -- `sobreCorpo` é o hover da zona ##faixasCorpo, submetida ANTES das
  -- linhas. Cada nome é um item submetido DEPOIS, cobrindo a coluna
  -- inteira, e numa sobreposição quem fica com o cursor é o de cima.
  -- Resultado: a zona perde o hover justamente sobre a coluna de nomes,
  -- que é onde se rola — a roda ali não fazia nada.
  --
  -- O retângulo não tem esse problema: ou o ponteiro está dentro da
  -- área das faixas, ou não está. IsMouseHoveringRect ainda respeita o
  -- recorte e os popups abertos; sem ela, a conta à mão serve.
  local naFaixa = sobreCorpo
  if not naFaixa then
    local emRect = Compat.get(ImGui, 'IsMouseHoveringRect')
    if emRect then
      local ok, v = pcall(emRect, ctx, x0, yc, x0 + largura, yc + corpo)
      naFaixa = (ok and v) or false
    else
      naFaixa = mx >= x0 and mx < x0 + largura
                and my >= yc and my < yc + corpo
    end
  end

  if naFaixa and ImGui.GetMouseWheel then
    -- O PRIMEIRO valor é a roda vertical, e é o que a roda comum move.
    --
    -- Eu li o segundo (a roda horizontal, que num mouse comum é sempre
    -- zero) e o zoom simplesmente não acontecia. Os dois usos que já
    -- existiam no projeto — o fader do renderer e os grupos de fader —
    -- sempre leram o primeiro; a evidência estava no próprio código.
    local roda = ImGui.GetMouseWheel(ctx)
    if roda and roda ~= 0 then
      if modAgora('Ctrl') then
        faixas.escalaV = math.max(0.6,
          math.min(2.5, (faixas.escalaV or 1) + roda * 0.12))
        encaixe.w = 0
      elseif not modAgora('Shift') and faixas.sobNome
             and faixas.sobNome.tipo == 'fader' and mx < x0 + GUTTER
             and session and faixas.sobNome.tag
             and session.byTag[faixas.sobNome.tag] then
        -- A RODA SOBRE UM FADER MOVE O FADER, não a lista.
        --
        -- É o gesto que a mão já faz sobre um fader no .form, e aqui não
        -- há por que ser outro. Rolar a lista continua possível de duas
        -- formas: Shift+roda, de qualquer lugar, e a roda sobre qualquer
        -- linha que não seja fader.
        --
        -- Um vigésimo por degrau: vinte cliques de roda percorrem o
        -- curso inteiro, que é o mesmo passo do fader no .form.
        local el = session.byTag[faixas.sobNome.tag]
        local v = (Session.faderValue(session, el) or 0) + roda * 0.05
        if v < 0 then v = 0 elseif v > 1 then v = 1 end
        faixas.acionar[#faixas.acionar + 1] =
          { element = el, kind = 'fader', value = v }
      elseif modAgora('Shift') or mx < x0 + GUTTER then
        faixas.rolagem = faixas.rolagem - roda * 24
      else
        zoomHorizontal(roda, opcoes.zoomNoMouse and tDe(mx)
                             or Transport.position())
      end
    end
  end
  if faixas.rolagem > excedente then faixas.rolagem = excedente end
  if faixas.rolagem < 0 then faixas.rolagem = 0 end

  if excedente > 0 then
    -- Barra de rolagem fina à direita, só quando há o que rolar.
    local frac = corpo / alturaTotal
    local hb = math.max(18, corpo * frac)
    local yb = yc + (corpo - hb) * (faixas.rolagem / excedente)
    ImGui.DrawList_AddRectFilled(dl, x0 + largura - 4, yb,
                                 x0 + largura - 1, yb + hb, 0x3A4150FF, 2)
  end

  -- O RETÂNGULO DO LAÇO, por cima das linhas e por baixo do cursor.
  if faixas.laco then
    local l = faixas.laco
    local xa, xb = math.min(l.x0, l.x1), math.max(l.x0, l.x1)
    local ya, yb = math.min(l.y0, l.y1), math.max(l.y0, l.y1)
    -- SEM PREENCHIMENTO, só o contorno.
    --
    -- Ele tinha um véu azul por dentro, e o véu escurecia justamente o
    -- que se está mirando: um bloco laranja debaixo do retângulo sumia
    -- enquanto a mão desenhava. Escolher o que não se vê não é escolher.
    --
    -- Um fio de um pixel basta para mostrar o alcance do gesto, e é o
    -- que o editor do REAPER faz.
    ImGui.DrawList_AddRect(dl, xa, ya, xb, yb, Theme.UI.accent, 2, 0, 1)
  end

  -- Cursor da música, por cima de tudo: a referência que liga as faixas
  -- à forma de onda.
  local cx = xDe(posicaoDeEscrita())
  ImGui.DrawList_AddLine(dl, cx, yc, cx, yc + corpo,
                         recording and Theme.UI.rec or 0x46D07AFF, 1.5)

  -- ------------------------------------------------- interação
  --
  -- SEM DICA EM CIMA DAS NOTAS, nem com as dicas ligadas.
  --
  -- Aqui a dica é o pior tipo: ela nasce exatamente onde a mão está
  -- trabalhando e cobre as linhas vizinhas — as que se está comparando
  -- para decidir onde arrastar. As outras dicas explicam um controle
  -- parado; esta atrapalhava o gesto em curso.
  if false and acertou and sobreCorpo then
    dicaSe( ('%s\n%s  →  %s\n\n%s')
      :format(acertou.linha.nome,
              Transport.formatTime(acertou.bloco.t0),
              Transport.formatTime(acertou.bloco.t1),
              (acertou.parte == 'meio'
                and 'Clique para selecionar.'
                or  'Arraste para mudar o ' ..
                    (acertou.parte == 'inicio' and 'início.' or 'fim.'))
              .. '\n\nDuplo clique  ·  apaga'
              .. '\nCtrl + duplo clique  ·  estende até o fim da música'
              .. '\nCtrl + Alt + clique  ·  preenche a música inteira'))
  end

  -- O CURSOR DIZ O QUE VAI ACONTECER, antes do clique.
  --
  -- Sem isso é preciso clicar para descobrir se pegou a borda ou o
  -- meio — e descobrir errado, aqui, é uma nota esticada sem querer.
  -- Setas horizontais na borda (o gesto é redimensionar), mão no meio
  -- (o gesto é escolher).
  if acertou and sobreCorpo and ImGui.SetMouseCursor then
    local qual = (acertou.parte == 'meio') and 'MouseCursor_Hand'
                                           or 'MouseCursor_ResizeEW'
    local c = Compat.const(ImGui, qual, nil)
    if c then pcall(ImGui.SetMouseCursor, ctx, c) end
  end

  -- GESTOS SOBRE UM BLOCO.
  --
  --   duplo clique              -> apaga
  --   Ctrl + duplo clique       -> estende até o FIM DA MÚSICA
  --   Ctrl + Alt + clique       -> preenche a MÚSICA INTEIRA
  --
  -- A diferença entre os dois preenchimentos é onde cada um COMEÇA: o
  -- Ctrl mantém o início onde está e só estica o fim; o Ctrl+Alt leva o
  -- começo para a abertura da música. Um é "isto vale daqui em diante",
  -- o outro é "isto vale a música toda".
  --
  -- Conferido ANTES do arrasto, e saindo em seguida: o clique também
  -- deixa o item ativo, e sem sair aqui o gesto começaria a arrastar a
  -- nota um instante antes de reescrevê-la.

  --- Reescreve o trecho de um bloco, absorvendo os que ficarem por baixo.
  --
  --  ABSORVER É OBRIGATÓRIO, não uma gentileza: dois trechos do mesmo
  --  controle sobrepostos são duas notas na mesma altura ao mesmo tempo,
  --  e o resultado na reprodução é imprevisível. Só somem os que caem
  --  DENTRO do novo trecho — o que está fora continua valendo.
  local function preencher(linha, bloco, de, ate, rotulo)
    -- O TRECHO PARA ONDE UM RIVAL COMEÇA.
    --
    -- Preencher "até o fim da música" não pode passar por cima de outro
    -- controle do mesmo grupo: eles se desligam mutuamente, e o que a
    -- tela mostrasse depois não seria o que a música faz. Parar antes é
    -- o único resultado honesto — e o registro diz que parou.
    local limite = Lanes.limiteAte(Lanes.rivais(faixas.linhas, linha), de, ate)
    if limite < ate then
      log(('%s: parou em %s — um controle do mesmo grupo entra ali')
        :format(linha.nome, Transport.formatTime(limite)))
      ate = limite
    end

    local absorvidos, certo = 0, false
    Timeline.editar('LumiBridge: ' .. rotulo, function()
      for _, b in ipairs(linha.blocos) do
        if b ~= bloco and b.t1 > de and b.t0 < ate
           and Timeline.deleteNoteAt(linha.pitch, b.t0) then
          absorvidos = absorvidos + 1
        end
      end
      -- O DESLIGAMENTO DEIXA DE EXISTIR: a nota agora vale até o fim da
      -- música, e um pulso apagando a luz lá dentro seria exatamente o
      -- contrário do que o gesto pediu. Deixá-lo era o defeito mais
      -- fácil de não notar aqui — só apareceria tocando a música.
      if bloco.fecho then
        Timeline.deleteNoteAt(linha.pitch, bloco.fecho.t0)
      end
      certo = Timeline.setNoteSpan(linha.pitch, bloco.t0, de, ate)
    end)

    log(('%s %s: %s → %s%s'):format(linha.nome, rotulo,
      Transport.formatTime(de), Transport.formatTime(ate),
      absorvidos > 0 and (' (%d trecho(s) absorvido(s))'):format(absorvidos) or ''))
    if not certo then log('  ...mas a nota não estava mais onde estava') end

    faixas.sel = { tag = linha.tag, pitch = linha.pitch,
                   nome = linha.nome, t0 = de }
    faixas.at = 0
  end

  local duplo   = Compat.get(ImGui, 'IsMouseDoubleClicked')
  local simples = Compat.get(ImGui, 'IsMouseClicked')

  local function apertou(fn)
    if not fn then return false end
    local ok, v = pcall(fn, ctx, 0)
    return ok and v == true
  end

  -- ---------------------------------- pontos de automação (fader)
  --
  --   arrastar um ponto  -> muda tempo E valor de uma vez
  --   duplo clique nele  -> apaga
  --   duplo clique vazio -> cria um ponto ali
  --
  -- Um ponto sozinho não faz nada visível: o valor entre dois pontos é
  -- interpolado, então mover um muda a rampa inteira que chega e a que
  -- sai dele. É por isso que arrastar (e ver a curva mudar) é o gesto
  -- certo aqui, e não digitar um número numa caixa.
  if noFader and not faixas.arrastePonto and not faixas.arraste then
    if ImGui.SetMouseCursor then
      local c = Compat.const(ImGui,
        noFader.ponto and 'MouseCursor_ResizeAll' or 'MouseCursor_Hand', nil)
      if c then pcall(ImGui.SetMouseCursor, ctx, c) end
    end

    dicaSe( noFader.ponto
      and ('%s  ·  %s  ·  %d%%\n\nArraste para mover.  Duplo clique apaga.')
          :format(noFader.linha.nome, Transport.formatTime(noFader.ponto.t),
                  math.floor(noFader.ponto.valor / 127 * 100 + 0.5))
      or ('%s  ·  %d%%\n\nDuplo clique cria um ponto aqui.')
          :format(noFader.linha.nome,
                  math.floor(noFader.valor / 127 * 100 + 0.5)))
  end

  if noFader and sobreCorpo and not faixas.arraste and not faixas.arrastePonto then
    if apertou(duplo) then
      local linha = noFader.linha
      if noFader.ponto then
        local foi = Timeline.editar('LumiBridge: apagar ponto', function()
          return Timeline.deleteCCAt(linha.cc, noFader.ponto.t)
        end)
        log(foi and ('%s: ponto apagado em %s'):format(linha.nome,
              Transport.formatTime(noFader.ponto.t))
            or 'nada apagado: o ponto não está mais onde estava')
      else
        local t = tDe(mx)
        Timeline.editar('LumiBridge: criar ponto', function()
          Timeline.write({ {
            kind = 'cc', channel = linha.canal or 1, cc = linha.cc,
            value = math.floor(noFader.valor + 0.5),
            qn = Timeline.timeToQN(t),
          } })
        end)
        log(('%s: ponto criado em %s a %d%%'):format(linha.nome,
          Transport.formatTime(t),
          math.floor(noFader.valor / 127 * 100 + 0.5)))
      end
      faixas.at = 0
      return CABECALHO + corpo + PEGA

    elseif ativoCorpo and noFader.ponto then
      -- ARRASTAR UM SELECIONADO LEVA A SELEÇÃO INTEIRA. Se o ponto
      -- pego não está na seleção, o gesto é dele sozinho e a seleção
      -- some — é o que se espera de clicar fora de uma seleção.
      local naSelecao = faixas.selCC[noFader.linha.tag]
                        and faixas.selCC[noFader.linha.tag][noFader.ponto.t]
      if not naSelecao then faixas.selCC = {} end
      faixas.arrastePonto = {
        emGrupo = naSelecao and true or nil,
        linha = noFader.linha, indice = noFader.indice,
        origem = noFader.ponto.t, origemValor = noFader.ponto.valor,
        ponto = noFader.ponto,
        t = noFader.ponto.t, valor = noFader.ponto.valor,
        -- A RÉGUA DA LINHA VAI JUNTO no arrasto.
        --
        -- O valor sob o cursor era lido de `noFader`, que só existe
        -- enquanto o mouse está DENTRO daquela linha — e arrastar um
        -- ponto até 100% tira o mouse dela quase sempre. Fora, a prévia
        -- parava de atualizar: o ponto ficava preso e o gesto parecia
        -- travado.
        yZero = noFader.yZero, yCheio = noFader.yCheio,
      }
    end
  end

  if faixas.arrastePonto then
    local a = faixas.arrastePonto
    if ativoCorpo then
      -- PRÉVIA enquanto o botão está pressionado, escrita só ao soltar:
      -- escrever a cada quadro encheria o desfazer de dezenas de passos
      -- para um gesto só.
      --
      -- O valor sai da régua GUARDADA, não da linha sob o mouse: depender
      -- dela era o que travava o arrasto assim que o cursor saía da faixa.
      local bruto = (a.yZero - my) / math.max(1, a.yZero - a.yCheio) * 127
      local t, v = Lanes.moverPonto(a.linha, a.indice, tDe(mx), bruto)
      a.t, a.valor = t, v
      a.ponto.t, a.ponto.valor = t, v

      -- A SELEÇÃO INTEIRA ANDA JUNTO NA PRÉVIA.
      --
      -- Só o ponto pego se movia enquanto o botão estava pressionado, e
      -- os outros saltavam para o lugar novo ao soltar. O gesto ficava
      -- às cegas: não dava para ver a forma da curva antes de confirmar,
      -- que é justamente o que se quer olhar ao mover vários pontos.
      --
      -- Os originais ficam guardados na primeira passagem — mover a
      -- partir dos valores já movidos acumularia o deslocamento a cada
      -- quadro, e a seleção fugiria da mão.
      if a.emGrupo then
        if not a.originais then
          a.originais = {}
          for tag, tempos in pairs(faixas.selCC) do
            for _, ln in ipairs(faixas.linhas) do
              if ln.tag == tag then
                for i2, p in ipairs(ln.pontos or {}) do
                  if tempos[p.t] then
                    a.originais[#a.originais + 1] =
                      { ponto = p, t = p.t, valor = p.valor,
                        tag = tag, indice = i2 }
                  end
                end
              end
            end
          end
        end
        local dt, dv = a.t - a.origem, a.valor - a.origemValor
        for _, o in ipairs(a.originais) do
          if o.ponto ~= a.ponto then
            o.ponto.t = o.t + dt
            o.ponto.valor = math.max(0, math.min(127, o.valor + dv))
          end
        end
      end
    elseif not ativoCorpo then
      faixas.arrastePonto = nil
      -- SÓ ESCREVE SE MUDOU, comparando com o que o ponto era ANTES
      -- do arrasto: a prévia já alterou o ponto na tela, então
      -- compará-lo consigo mesmo daria sempre "não mudou".
      if math.abs(a.t - a.origem) > 0.001 or a.valor ~= a.origemValor then
        local dt = a.t - a.origem
        local dv = a.valor - a.origemValor
        -- Os originais guardados na prévia são a fonte da verdade: os
        -- pontos na tela já estão deslocados, e escrever a partir deles
        -- moveria tudo duas vezes.
        if a.originais then
          for _, o in ipairs(a.originais) do
            o.ponto.t, o.ponto.valor = o.t, o.valor
          end
        end
        -- `ok` DECLARADO FORA da função, e lido fora dela.
        --
        -- Era `local ok` DENTRO do bloco e `log(ok and ...)` fora: o log
        -- lia um global inexistente e dizia "não movi o ponto" toda vez
        -- que o ponto tinha sido movido. É o mesmo descuido que a
        -- conversão para blocos de desfazer já tinha deixado em quatro
        -- lugares; este era o quinto, e passou porque a mentira estava
        -- só no registro.
        local ok = false
        Timeline.editar('LumiBridge: mover ponto', function()
        ok = Timeline.setCCPoint(a.linha.cc, a.linha.canal,
                                 a.origem, a.t, a.valor)

        -- OS OUTROS SELECIONADOS ANDAM O MESMO TANTO, no MESMO bloco de
        -- desfazer: um gesto, um Ctrl+Z. Movidos pelo DELTA, e não para
        -- a posição do que foi pego, senão todos se empilhariam em cima
        -- dele e a forma da curva se perderia.
        --
        -- De trás para a frente no tempo quando o movimento é para a
        -- frente: mover o primeiro para cima do segundo antes de o
        -- segundo sair faria os dois disputarem o mesmo instante.
        if a.emGrupo then
          for tag, tempos in pairs(faixas.selCC) do
            local ln
            for _, cand in ipairs(faixas.linhas) do
              if cand.tag == tag then ln = cand break end
            end
            if ln and ln.cc then
              local lista = {}
              for t in pairs(tempos) do lista[#lista + 1] = t end
              table.sort(lista, function(p, q)
                if dt >= 0 then return p > q else return p < q end
              end)
              for _, t in ipairs(lista) do
                if not (tag == a.linha.tag
                        and math.abs(t - a.origem) < 0.0005) then
                  local valorAntigo
                  for _, p in ipairs(ln.pontos or {}) do
                    if math.abs(p.t - t) < 0.0005 then valorAntigo = p.valor end
                  end
                  if valorAntigo then
                    local nv = math.max(0, math.min(127,
                                                    valorAntigo + dv))
                    Timeline.setCCPoint(ln.cc, ln.canal, t, t + dt,
                                        math.floor(nv + 0.5))
                  end
                end
              end
            end
          end
          faixas.selCC = {}
        end
        end)
        log(ok and ('%s: ponto em %s a %d%%'):format(a.linha.nome,
              Transport.formatTime(a.t),
              math.floor(a.valor / 127 * 100 + 0.5))
            or 'não movi o ponto: ele não está mais onde estava')
        faixas.at = 0
      end
    end
  end

  -- DEL APAGA A SELEÇÃO INTEIRA, num bloco de desfazer só.
  --
  -- Antes o Del só alcançava o bloco selecionado; com vários pontos
  -- marcados, apagá-los um a um era o trabalho que a seleção existe para
  -- evitar.
  if (next(faixas.selCC) ~= nil or next(faixas.selNotas) ~= nil)
     and ImGui.IsKeyPressed then
    local kDel = Compat.const(ImGui, 'Key_Delete', nil)
    local okDel, foiDel = false, false
    if kDel then okDel, foiDel = pcall(ImGui.IsKeyPressed, ctx, kDel) end
    if okDel and foiDel then
      local quantos, notas = 0, 0
      Timeline.editar('LumiBridge: apagar a seleção', function()
        for tag, tempos in pairs(faixas.selCC) do
          local ln
          for _, cand in ipairs(faixas.linhas) do
            if cand.tag == tag then ln = cand break end
          end
          if ln and ln.cc then
            for t in pairs(tempos) do
              if Timeline.deleteCCAt(ln.cc, t) then quantos = quantos + 1 end
            end
          end
        end
        -- E AS NOTAS, cada uma com o desligamento dela. Um pulso sem a
        -- nota que ele fecha continuaria apagando a luz naquele
        -- instante, agora sem nada antes para desligar.
        for tag, inicios in pairs(faixas.selNotas) do
          local ln
          for _, cand in ipairs(faixas.linhas) do
            if cand.tag == tag then ln = cand break end
          end
          if ln and ln.pitch then
            for t0 in pairs(inicios) do
              local fecho
              for _, b in ipairs(ln.blocos or {}) do
                if math.abs(b.t0 - t0) < 0.002 then fecho = b.fecho break end
              end
              if fecho then Timeline.deleteNoteAt(ln.pitch, fecho.t0) end
              if Timeline.deleteNoteAt(ln.pitch, t0) then notas = notas + 1 end
            end
          end
        end
      end)
      faixas.selCC, faixas.selNotas = {}, {}
      faixas.sel = nil
      faixas.at = 0
      log(('%d ponto(s) e %d nota(s) apagados'):format(quantos, notas))
    end
  end

  Window.__dbgClick = { acertou ~= nil, sobreCorpo, mx, my, yc, corpo }
  -- BOTÃO DIREITO: LAÇO SE ANDAR, MENU SE NÃO ANDAR.
  --
  -- É o gesto do editor MIDI do próprio REAPER, e foi assim que ele foi
  -- pedido. Antes a seleção era com o botão esquerdo arrastado no vazio,
  -- e isso disputava com o gesto de levar o cursor da música — que é o
  -- mais usado da tela.
  --
  -- Com o direito não há disputa: arrastar seleciona, clicar parado abre
  -- o menu do bloco. O menu não se perde, e o esquerdo volta a ser só o
  -- cursor.
  if sobreCorpo and mx >= x0 + GUTTER and ImGui.IsMouseClicked
     and not faixas.laco then
    -- Botão 1 é o direito no ImGui. Via pcall porque IsMouseClicked com
    -- dois argumentos não existe em toda geração do ReaImGui, e ali um
    -- erro derrubaria o quadro inteiro.
    local ok, foi = pcall(ImGui.IsMouseClicked, ctx, 1)
    if ok and foi then
      -- O INSTANTE DO CLIQUE vai junto. Dentro do popup o ponteiro já
      -- se moveu para o item do menu, e "aqui" quer dizer onde o menu
      -- foi aberto, não onde ele foi escolhido.
      faixas.laco = {
        x0 = mx, y0 = my, x1 = mx, y1 = my, botao = 1,
        menu = acertou and { linha = acertou.linha, bloco = acertou.bloco,
                             t = tDe(mx) } or nil,
      }
    end
  end

  if ImGui.BeginPopup(ctx, 'acoesDoBloco') then
    local m = faixas.menuBloco
    if m then
      ImGui.TextColored(ctx, Theme.UI.textDim, m.linha.nome)
      ImGui.Separator(ctx)
      if ImGui.Selectable(ctx, 'Juntar com o próximo trecho   Ctrl+J') then
        juntarBlocos(m.linha, m.bloco)
      end
      -- COMEÇAR AQUI, o par de "Terminar aqui".
      --
      -- Uma nota colada no início da música tem a borda esquerda em cima
      -- da divisória da coluna de nomes. A divisória saiu de lá, mas o
      -- menu resolve também o caso em que a borda está fora da vista —
      -- rolada para a esquerda, sem nada para agarrar.
      if m.t and m.t < m.bloco.t1 - 0.01
         and ImGui.Selectable(ctx, 'Começar aqui') then
        local de = m.t
        Timeline.editar('LumiBridge: começar aqui', function()
          Timeline.setNoteSpan(m.linha.pitch, m.bloco.t0, de, m.bloco.t1)
        end)
        faixas.at = 0
        faixas.sel = nil
        log(('%s começa em %s'):format(m.linha.nome,
          Transport.formatTime(de)))
      end

      -- TERMINAR AQUI, sem arrastar a borda.
      --
      -- Uma nota que vai até o fim da música tem a borda direita no
      -- limite da janela, e ali quem pega o mouse é a moldura do
      -- REAPER: arrastar redimensiona a janela em vez de encurtar a
      -- nota. Relatado assim, com essas palavras. Encurtar pelo menu não
      -- depende de alcançar a borda, e serve também para a nota cuja
      -- borda está fora da vista.
      if m.t and m.t > m.bloco.t0 + 0.01
         and ImGui.Selectable(ctx, 'Terminar aqui') then
        local ate = m.t
        Timeline.editar('LumiBridge: terminar aqui', function()
          -- O pulso de desligamento vai junto, e ANTES da nota longa:
          -- mesma ordem do arrasto de borda, pelo mesmo motivo — mover a
          -- nota primeiro faria a busca por posição achar o pulso errado.
          if m.bloco.fecho then
            Timeline.setNoteSpan(m.linha.pitch, m.bloco.fecho.t0, ate,
                                 ate + (m.bloco.fecho.t1 - m.bloco.fecho.t0))
          end
          Timeline.setNoteSpan(m.linha.pitch, m.bloco.t0, m.bloco.t0, ate)
        end)
        faixas.at = 0
        log(('%s termina em %s'):format(m.linha.nome,
          Transport.formatTime(ate)))
      end
      if ImGui.Selectable(ctx, 'Estender até o fim da música') then
        Timeline.editar('LumiBridge: estender até o fim', function()
        if m.bloco.fecho then
          Timeline.deleteNoteAt(m.linha.pitch, m.bloco.fecho.t0)
        end
        Timeline.setNoteSpan(m.linha.pitch, m.bloco.t0, m.bloco.t0,
                             region.endTime)
        end)
        faixas.at = 0
      end
      if ImGui.Selectable(ctx, 'Apagar   Del') then
        Timeline.editar('LumiBridge: apagar nota', function()
        if m.bloco.fecho then
          Timeline.deleteNoteAt(m.linha.pitch, m.bloco.fecho.t0)
        end
        Timeline.deleteNoteAt(m.linha.pitch, m.bloco.t0)
        end)
        faixas.sel, faixas.at = nil, 0
      end
    end
    ImGui.EndPopup(ctx)
  end

  if acertou and sobreCorpo and not faixas.arraste then
    local linha, bloco = acertou.linha, acertou.bloco
    local ctrl = modAgora('Ctrl')

    if ctrl and modAgora('Alt') and apertou(simples) then
      preencher(linha, bloco, pontoDeAbertura(), region.endTime,
                'preenche a música inteira')
      return CABECALHO + corpo + PEGA

    elseif apertou(duplo) then
      if ctrl then
        preencher(linha, bloco, bloco.t0, region.endTime,
                  'estendido até o fim')
      else
        local certo

        Timeline.editar('LumiBridge: apagar nota', function()
        -- E O DESLIGAMENTO JUNTO. Um pulso sem a nota que ele fecha
        -- continuaria apagando a luz naquele instante, agora sem nada
        -- antes para desligar — um comando fantasma no meio da música.
        if bloco.fecho then
          Timeline.deleteNoteAt(linha.pitch, bloco.fecho.t0)
        end
        certo = Timeline.deleteNoteAt(linha.pitch, bloco.t0)
        end)
        log(certo and ('%s apagado em %s'):format(linha.nome,
              Transport.formatTime(bloco.t0))
            or 'nada apagado: a nota não está mais onde estava')
        faixas.sel = nil
        faixas.at = 0
      end
      return CABECALHO + corpo + PEGA
    end
  end

  if ativoCorpo and acertou and not faixas.arraste then
    -- PEGAR FORA DA SELEÇÃO A DESFAZ, como em qualquer editor: clicar
    -- num bloco que não está marcado quer dizer "é este agora".
    local naSelecao = Lanes.marcada(faixas.selNotas, acertou.linha.tag,
                                    acertou.bloco.t0)
    if not naSelecao then faixas.selNotas = {} end

    faixas.sel = { tag = acertou.linha.tag, pitch = acertou.linha.pitch,
                   nome = acertou.linha.nome, t0 = acertou.bloco.t0,
                   fecho = acertou.bloco.fecho }
    -- O MEIO TAMBÉM ARRASTA, e agora move o trecho inteiro.
    --
    -- Ficava de fora: o ponteiro virava mãozinha sobre o meio de um
    -- bloco e o arrasto não fazia nada. `pega` guarda a que distância do
    -- início a mão pegou o bloco, para ele não saltar para debaixo do
    -- ponteiro no primeiro pixel.
    faixas.arraste = {
      linha = acertou.linha, bloco = acertou.bloco, parte = acertou.parte,
      origem = acertou.bloco.t0, origemT1 = acertou.bloco.t1,
      t0 = acertou.bloco.t0, t1 = acertou.bloco.t1,
      pega = (acertou.parte == 'meio') and (tDe(mx) - acertou.bloco.t0) or 0,
    }

    -- O RESTO DA SELEÇÃO VAI JUNTO — movendo OU esticando.
    --
    -- Esticar em grupo ficou de fora na primeira volta, por eu achar que
    -- "todas ficam 200ms mais longas" não era um pedido que alguém
    -- fizesse arrastando. Era: regravar um trecho e precisar alongar as
    -- cinco notas dele na mesma medida é rotina.
    --
    -- A borda anda pelo mesmo DELTA em todas, e cada uma continua parando
    -- no vizinho dela — o limite é de cada bloco, não do gesto.
    if naSelecao then
      local grupo = {}
      for _, ln in ipairs(faixas.linhas) do
        if ln.pitch then
          for _, b in ipairs(ln.blocos or {}) do
            if b ~= acertou.bloco
               and Lanes.marcada(faixas.selNotas, ln.tag, b.t0) then
              grupo[#grupo + 1] = { linha = ln, bloco = b,
                                    origem = b.t0, origemT1 = b.t1,
                                    fecho = b.fecho,
                                    fechoT0 = b.fecho and b.fecho.t0,
                                    fechoT1 = b.fecho and b.fecho.t1 }
            end
          end
        end
      end
      if #grupo > 0 then faixas.arraste.grupo = grupo end
    end
  end

  if faixas.arraste then
    if ativoCorpo then
      -- PRÉVIA enquanto o botão está pressionado; a escrita acontece uma
      -- vez, ao soltar. Escrever a cada quadro encheria o desfazer de
      -- dezenas de passos para um único gesto.
      local minimo = Timeline.qnToTime(Timeline.timeToQN(region.startTime)
                                       + Timeline.projectGrid())
                     - region.startTime
      -- O ÍMÃ, ANTES DA REGRA DE ARRASTO. A tolerância vem em PIXELS e
      -- vira tempo pela escala da vista: aproximar o zoom aperta o ímã,
      -- que é o jeito de pedir precisão sem desligá-lo.
      -- Movendo o bloco inteiro, o destino é onde o INÍCIO deve cair:
      -- o ponto em que a mão pegou é descontado antes de tudo, inclusive
      -- do ímã — assim quem gruda na batida é a borda do bloco, e não o
      -- ponteiro.
      local puxado = tDe(mx) - (faixas.arraste.pega or 0)
      if opcoes.ima then
        puxado = Lanes.imantar(faixas.linhas, puxado, escala * 8,
                               faixas.arraste.bloco)
      end
      local t0, t1 = Lanes.arrastar(faixas.arraste.linha, faixas.arraste.bloco,
                                    faixas.arraste.parte, puxado, minimo,
                                    Lanes.rivais(faixas.linhas,
                                                 faixas.arraste.linha))
      faixas.arraste.t0, faixas.arraste.t1 = t0, t1
      faixas.arraste.bloco.t0, faixas.arraste.bloco.t1 = t0, t1

      -- O GRUPO ANDA PELO MESMO TANTO, e é isso que se vê arrastando.
      --
      -- Pelo DELTA do bloco pego, não recalculando cada um: o delta é o
      -- gesto, e é ele que já passou pelo ímã e pelos limites daquele
      -- bloco. Reaplicar a regra em cada um deixaria o conjunto
      -- deformado — um esbarra num vizinho, para, e os outros seguem.
      -- O DELTA É O DO GESTO, e qual ponta ele move depende da parte
      -- pega: no meio andam as duas, numa borda anda só ela.
      local parte = faixas.arraste.parte
      local delta = (parte == 'fim') and (t1 - faixas.arraste.origemT1)
                                     or (t0 - faixas.arraste.origem)
      for _, g in ipairs(faixas.arraste.grupo or {}) do
        local n0 = (parte == 'fim') and g.origem or (g.origem + delta)
        local n1 = (parte == 'inicio') and g.origemT1 or (g.origemT1 + delta)
        -- Nunca ao contrário nem sumida: uma célula de grade é o piso,
        -- o mesmo que a borda de um bloco só respeita.
        if n1 < n0 + minimo then
          if parte == 'inicio' then n0 = n1 - minimo else n1 = n0 + minimo end
        end
        g.bloco.t0, g.bloco.t1 = n0, n1
        -- O desligamento acompanha o FIM, com a duração que ele tinha.
        if g.fecho then
          g.fecho.t0 = n1 + (g.fechoT0 - g.origemT1)
          g.fecho.t1 = g.fecho.t0 + (g.fechoT1 - g.fechoT0)
        end
      end
    else
      local a = faixas.arraste
      faixas.arraste = nil
      -- SÓ ESCREVE SE MUDOU. Um clique na borda sem arrastar é um
      -- clique de seleção, e gastar um passo de desfazer com ele
      -- entulharia o histórico de coisa nenhuma.
      if math.abs(a.t0 - a.origem) > 0.001
         or math.abs(a.t1 - a.origemT1) > 0.001 then
        local fecho
        -- DECLARADO AQUI, e não dentro do closure: lá dentro ele era um
        -- local novo, e o `if` abaixo lia o `ok` do pcall do botão
        -- direito — um valor de outro assunto, quase sempre verdadeiro.
        -- O registro dizia "ajustado" mesmo quando a nota não fora
        -- achada.
        local certo

        Timeline.editar('LumiBridge: ajustar nota', function()

        -- O DESLIGAMENTO VAI JUNTO, e ANTES da nota longa.
        --
        -- Foi decisão explícita: aumentar a nota à mão leva o
        -- desligamento junto; regravar por cima é outro caminho, e a
        -- gravação escreve o seu próprio pulso. Sem isto, esticar um
        -- bloco deixaria o pulso onde estava — apagando a luz no meio do
        -- trecho que você acabou de estender.
        --
        -- Primeiro o pulso, depois a nota: movendo a nota antes, o fim
        -- dela passaria por cima do pulso na posição antiga, e a busca
        -- por posição poderia achar o alvo errado.
        fecho = a.bloco.fecho
        if fecho then
          Timeline.setNoteSpan(a.linha.pitch, fecho.t0, a.t1,
                               a.t1 + (fecho.t1 - fecho.t0))
        end

        certo = Timeline.setNoteSpan(a.linha.pitch, a.origem, a.t0, a.t1)

        -- E O RESTO DA SELEÇÃO, pelo mesmo delta — movida ou esticada.
        --
        -- Cada bloco já está com as posições novas na lista (a prévia do
        -- arrasto as escreveu), e é de lá que elas saem: repetir aqui a
        -- conta dos limites daria uma resposta e o olho tinha visto
        -- outra.
        --
        -- NA ORDEM CERTA. As notas são achadas por posição; indo para a
        -- frente, a primeira pararia em cima da segunda e a busca da
        -- segunda acharia a errada. Da última para a primeira (e ao
        -- contrário, quando o gesto é para trás), cada uma sai do lugar
        -- antes de alguém chegar nele.
        local paraFrente = (a.t0 - a.origem) + (a.t1 - a.origemT1) >= 0
        local ordem = {}
        for _, g in ipairs(a.grupo or {}) do ordem[#ordem + 1] = g end
        table.sort(ordem, function(p, q)
          if paraFrente then return p.origem > q.origem end
          return p.origem < q.origem
        end)
        for _, g in ipairs(ordem) do
          if g.fechoT0 and g.fecho then
            Timeline.setNoteSpan(g.linha.pitch, g.fechoT0,
                                 g.fecho.t0, g.fecho.t1)
          end
          Timeline.setNoteSpan(g.linha.pitch, g.origem,
                               g.bloco.t0, g.bloco.t1)
        end
        end)

        -- A SELEÇÃO ACOMPANHA. Ela é guardada por posição, e as posições
        -- acabaram de mudar: sem isto o contorno azul some no quadro
        -- seguinte e um Del logo depois não acha mais nada.
        if a.grupo then
          local nova = {}
          local d = a.t0 - a.origem
          for tag, inicios in pairs(faixas.selNotas) do
            nova[tag] = {}
            for t0 in pairs(inicios) do nova[tag][t0 + d] = true end
          end
          faixas.selNotas = nova
        end

        -- E O REGISTRO diz o que o gesto foi, não só que houve um.
        if a.grupo and certo then
          log((a.parte == 'meio')
            and ('%d nota(s) movidas em %s'):format(#a.grupo + 1,
                  Transport.formatTime(math.abs(a.t0 - a.origem)))
            or ('%d nota(s): borda %s movida em %s'):format(#a.grupo + 1,
                  a.parte == 'fim' and 'final' or 'inicial',
                  Transport.formatTime(math.abs(
                    (a.parte == 'fim') and (a.t1 - a.origemT1)
                                        or (a.t0 - a.origem)))))
        end

        if certo then
          faixas.sel = { tag = a.linha.tag, pitch = a.linha.pitch, t0 = a.t0 }
          if not a.grupo then
            log(('%s ajustado: %s → %s'):format(a.linha.nome,
                  Transport.formatTime(a.t0), Transport.formatTime(a.t1)))
          end
        else
          log('não consegui ajustar a nota: ela não está mais onde estava')
        end
        faixas.at = 0
      end
    end
  end

  -- MENU DE COR, desenhado todo quadro como qualquer popup do ImGui.
  local popCor, padCor = abrirPopup('corDaFaixa')
  if popCor then
    local tag = faixas.menuCor
    ImGui.TextColored(ctx, Theme.UI.text, faixas.menuNome or 'Linha')
    ImGui.Separator(ctx)

    if ImGui.Selectable(ctx, 'Padrão do grupo',
                        not (faixas.escolhidas or {})[tag]) then
      escolherCor(tag, nil)
    end

    -- A TECLA F1-F12 DESTE CONTROLE, que no .form sai do clique direito
    -- no próprio botão. O menu é OUTRO popup, e abrir um popup de dentro
    -- de outro não funciona: o pedido fica guardado e é atendido no
    -- quadro seguinte, junto de drawFKeyMenu.
    if faixas.menuEl then
      if ImGui.Selectable(ctx, 'Atribuir tecla F1-F12...') then
        faixas.pedirTeclaF = faixas.menuEl
      end
      ImGui.Separator(ctx)
    end
    ImGui.TextColored(ctx, Theme.UI.textDim, 'COR')

    local dlPop = ImGui.GetWindowDrawList(ctx)
    for i, c in ipairs(Lanes.CORES) do
      local cx, cy = ImGui.GetCursorScreenPos(ctx)
      -- Uma amostra da cor antes do nome: escolher cor lendo "vermelho"
      -- numa lista é ler, não escolher.
      if ImGui.Selectable(ctx, '        ' .. tostring(i),
                          (faixas.escolhidas or {})[tag] == i) then
        escolherCor(tag, i)
      end
      ImGui.DrawList_AddRectFilled(dlPop, cx + 2, cy + 2, cx + 20, cy + 14,
                                   Theme.rgba(c), 2)
    end
    ImGui.EndPopup(ctx)
    if padCor then pcall(ImGui.PopStyleVar, ctx, 1) end
  end

  -- DIVISÓRIA DA COLUNA DE NOMES: arraste para alargar ou estreitar.
  --
  -- No lugar certo — sobre a própria linha que separa as duas áreas. Um
  -- controle à parte para isso seria mais um botão para aprender; a
  -- divisória já está ali e é onde a mão vai.
  --
  -- O ALVO FICA TODO DO LADO DOS NOMES, e não montado sobre a linha.
  --
  -- Eram dez pixels centrados na divisória, cinco deles JÁ DENTRO da
  -- área das notas — e a divisória é submetida depois das linhas, então
  -- ficava com o cursor ali. Uma nota que começa colada no início da
  -- música tem a borda esquerda exatamente nesses pixels: tentar
  -- encurtá-la mexia na largura da coluna. Relatado assim.
  --
  -- Oito pixels, todos à esquerda da linha. Continua sendo um alvo
  -- confortável — a mão vem da coluna de nomes, que é o lado de onde se
  -- puxa — e devolve à nota a borda que é dela.
  ImGui.SetCursorScreenPos(ctx, x0 + GUTTER - 8, yc)
  ImGui.InvisibleButton(ctx, '##faixasGutter', 8, corpo)
  local sobreDiv = ImGui.IsItemHovered(ctx)
  if sobreDiv or (ImGui.IsItemActive and ImGui.IsItemActive(ctx)) then
    ImGui.DrawList_AddRectFilled(dl, x0 + GUTTER - 1, yc,
                                 x0 + GUTTER + 1, yc + corpo, Theme.UI.accent)
    if ImGui.SetMouseCursor then
      local c = Compat.const(ImGui, 'MouseCursor_ResizeEW', nil)
      if c then pcall(ImGui.SetMouseCursor, ctx, c) end
    end
    if sobreDiv then
      dicaSe( 'Arraste para mudar a largura da coluna de nomes.')
    end
  end
  if ImGui.IsItemActive and ImGui.IsItemActive(ctx) then
    faixas.gutter = math.max(60, math.min(360, mx - x0))
    faixas.salvarEm = agora + 0.5
  end

  -- CLICAR NO VAZIO LEVA O CURSOR DA MÚSICA ATÉ ALI.
  --
  -- A faixa já é uma régua de tempo alinhada com a forma de onda; clicar
  -- nela e nada acontecer é a resposta errada. Só no VAZIO, porque em
  -- cima de um bloco ou de um ponto o clique já tem dono — selecionar e
  -- arrastar, respectivamente.
  --
  -- Gravando, saltarPara recusa por conta própria (mover o cursor no meio
  -- de uma gravação mexe justamente no que está sendo escrito), e a
  -- recusa já se explica na dica da timeline.
  -- DUPLO CLIQUE NO VAZIO DE UMA LINHA DE BOTÃO CRIA A NOTA.
  --
  -- Dava para esticar, encurtar, juntar e apagar — tudo sobre notas que
  -- já existiam — e a única forma de fazer a primeira aparecer era
  -- gravando. Quem edita à mão precisa acrescentar tanto quanto precisa
  -- tirar.
  --
  -- Duplo clique porque é o gesto de qualquer editor MIDI, e porque o
  -- clique simples no vazio já tem dono: leva o cursor da música.
  --
  -- Nasce com uma célula da grade, como as notas da gravação: é a menor
  -- duração que o Lumikit distingue, e esticar depois é um arrasto.
  if sobreCorpo and apertou(duplo) and not acertou and not noFader
     and mx >= x0 + GUTTER then
    -- Qual linha está sob o ponteiro, pela mesma régua que desenhou as
    -- alturas. É a única fonte que vale para a área de tempo.
    local alvoLinha, yAcc = nil, yc - faixas.rolagem
    for iL, hL in ipairs((faixas.geom or {}).alturas or {}) do
      if my >= yAcc and my < yAcc + hL then
        alvoLinha = faixas.linhas[iL]
        break
      end
      yAcc = yAcc + hL
    end
    if alvoLinha and alvoLinha.tipo ~= 'fader' and alvoLinha.pitch then
    local celula = Timeline.qnToTime(Timeline.timeToQN(region.startTime)
                                     + Timeline.projectGrid())
                   - region.startTime
    local t0 = tDe(mx)
    if opcoes.ima then
      t0 = Lanes.imantar(faixas.linhas, t0, escala * 8)
    end
    local criou = false
    Timeline.editar('LumiBridge: criar nota', function()
      criou = Timeline.inserirNota(alvoLinha.pitch, alvoLinha.canal,
                                   t0, t0 + math.max(celula, 0.05))
    end)
    if criou then
      log(('%s: nota criada em %s'):format(alvoLinha.nome,
                                           Transport.formatTime(t0)))
      faixas.at = 0
    else
      log('não consegui criar a nota: a música tem item MIDI aqui?')
    end
    end
  end

  -- LAÇO DE SELEÇÃO nos pontos de CC.
  --
  -- Arrastar no vazio de uma linha de FADER passa a desenhar um
  -- retângulo e selecionar os pontos dentro dele. Nas linhas de botão o
  -- arrasto continua levando o cursor da música: lá não há ponto nenhum
  -- para selecionar, e tirar aquele gesto seria perder o mais usado da
  -- tela por um que não teria efeito.
  if faixas.laco then
    faixas.laco.x1, faixas.laco.y1 = mx, my
    -- QUEM SEGURA É O BOTÃO QUE COMEÇOU. O laço do direito não é
    -- "item ativo" para o ImGui — item ativo é coisa do esquerdo —,
    -- então perguntar por ativoCorpo o encerraria no quadro seguinte ao
    -- de nascer, sem nunca chegar a ter tamanho.
    local segurando = ativoCorpo
    if faixas.laco.botao == 1 then
      segurando = false
      if ImGui.IsMouseDown then
        local okD, baixo = pcall(ImGui.IsMouseDown, ctx, 1)
        segurando = (okD and baixo) or false
      end
    end
    if not segurando then
      -- SOLTOU: converte o retângulo em seleção.
      local l = faixas.laco
      local xa, xb = math.min(l.x0, l.x1), math.max(l.x0, l.x1)
      local ya, yb = math.min(l.y0, l.y1), math.max(l.y0, l.y1)
      faixas.laco = nil
      faixas.selCC, faixas.selNotas = {}, {}
      -- Um clique parado não é um laço: dois pixels de tolerância
      -- separam "arrastei um retângulo" de "cliquei e o mouse tremeu".
      if (xb - xa) > 2 or (yb - ya) > 2 then
        local yl = yc - faixas.rolagem
        for _, ln in ipairs(faixas.linhas) do
          local hl = math.floor(((ln.tipo == 'fader') and ALTURA_FADER
                                 or ALTURA_BOTAO) * (faixas.escalaV or 1))
          if yl < yb and yl + hl > ya then
            if ln.tipo == 'fader' then
              local yZero, yCheio = yl + hl - 4, yl + 4
              for _, p in ipairs(ln.pontos or {}) do
                local px = xDe(p.t)
                local py = yZero - (p.valor / 127) * (yZero - yCheio)
                if px >= xa and px <= xb and py >= ya and py <= yb then
                  faixas.selCC[ln.tag] = faixas.selCC[ln.tag] or {}
                  faixas.selCC[ln.tag][p.t] = true
                end
              end
            else
              -- UM BLOCO ENTRA SE ENCOSTA no retângulo, e não só se
              -- couber inteiro dentro dele: uma nota que atravessa a
              -- vista é mais comprida que qualquer laço que a mão
              -- desenhe, e exigir que coubesse a tornaria inselecionável.
              for _, b in ipairs(ln.blocos or {}) do
                if xDe(b.t1) >= xa and xDe(b.t0) <= xb then
                  faixas.selNotas[ln.tag] = faixas.selNotas[ln.tag] or {}
                  faixas.selNotas[ln.tag][b.t0] = true
                end
              end
            end
          end
          yl = yl + hl
        end
      elseif l.menu then
        -- NÃO ANDOU, e havia bloco embaixo: é o menu do bloco.
        faixas.menuBloco = l.menu
        ImGui.OpenPopup(ctx, 'acoesDoBloco')
      end
    end
  end

  -- A COLUNA DE NOMES NÃO É ÁREA VAZIA.
  --
  -- Esta zona cobre a faixa inteira, nomes inclusive, e tratava um
  -- clique ali como "leve o cursor para cá". Enquanto o nome era só um
  -- rótulo isso passava despercebido; agora que ele é um BOTÃO, apertá-lo
  -- mandava o cursor junto para o começo da vista — acionar um controle
  -- virava um salto na música, e o que se gravava saía no lugar errado.
  if sobreCorpo and apertou(simples) and not acertou
     and mx >= x0 + GUTTER
     and not (noFader and noFader.ponto)
     and not faixas.arraste and not faixas.arrastePonto then
    -- O ESQUERDO É O CURSOR, de novo.
    --
    -- Ele chegou a começar o laço nas linhas de botão, e era disputa: o
    -- clique no vazio para levar o cursor é o gesto mais usado da tela.
    -- A seleção múltipla passou para o botão direito (ver acima), como
    -- no editor do REAPER, e o esquerdo voltou a ter um dono só.
    --
    -- Nas linhas de FADER o laço com o esquerdo fica: ali não há o gesto
    -- do cursor competindo, e foi assim que ele foi pedido.
    if noFader then
      faixas.laco = { x0 = mx, y0 = my, x1 = mx, y1 = my }
      faixas.selCC, faixas.selNotas = {}, {}
    else
      saltarPara(tDe(mx), false)
    end
  end

  -- --------------------------------------------- pega de altura
  --
  -- Só quando há o que ajustar.
  --
  -- Em COLUNA quem divide a tela é a divisória vertical de quem chamou.
  -- Em INTEIRA as faixas ocupam a janela e não há nada embaixo para
  -- ceder espaço: a pega ficava lá, ocupando uma tira e sugerindo um
  -- ajuste que não existe. Sair de "inteira" é o botão do cabeçalho, que
  -- é onde se entrou.
  if aoLado or faixas.inteira then
    return CABECALHO + ONDA + corpo
  end

  local yp = yc + corpo
  ImGui.SetCursorScreenPos(ctx, x0, yp)
  ImGui.InvisibleButton(ctx, '##faixasPega', largura, PEGA)
  local sobrePega = ImGui.IsItemHovered(ctx)
  ImGui.DrawList_AddRectFilled(dl, x0, yp, x0 + largura, yp + PEGA,
                               sobrePega and Theme.UI.accent or Theme.UI.panel)
  if sobrePega then
    dicaSe( 'Arraste para mudar a altura das faixas.')
  end
  if ImGui.IsItemActive and ImGui.IsItemActive(ctx) then
    -- Arrastar a divisória sai do modo "inteira": pedir uma altura é
    -- pedir para dividir a tela.
    faixas.inteira = false
    faixas.altura = math.max(40, math.min(teto, my - yc))
    encaixe.w = 0
    faixas.salvarEm = agora + 0.5
  end

  return CABECALHO + corpo + PEGA
end

--- Barra de transporte: play, posição e navegação por região.
--
--  Programar iluminação é repetir o mesmo trecho muitas vezes. Ter de
--  alternar para a janela do REAPER a cada volta quebra o ritmo, então
--  o transporte fica aqui dentro.
--- Botão de transporte desenhado à mão, no estilo do REAPER.
--
--  Os símbolos são desenhados na DrawList em vez de escritos como texto:
--  glifos de fonte variam de tamanho e alinhamento entre versões, e o
--  resultado ficava desalinhado. Desenhados, ficam sempre iguais.
--
--  @param kind 'play' | 'pause' | 'stop' | 'rec' | 'prev' | 'next'
--  @return boolean clicado
local function transportButton(kind, ativo, textoDica, distintivo)
  -- 34px, e os desenhos ocupando ~22px dele.
  --
  -- A V107 tinha REDUZIDO os ícones de 22 para 16px por ficarem gordos
  -- demais — mas naquela época o botão era 30px e não havia agrupamento
  -- nenhum. Com o botão maior, o mesmo 22px lê como cheio, não gordo, e
  -- 16px passou a parecer perdido no meio do espaço.
  local D = M.botao
  -- CONTA A SI MESMO.
  --
  -- A repartição da barra precisa saber quanto os blocos ocupam, e medir
  -- isso pelo cursor do ImGui dependia de uma função que nem toda
  -- instalação tem. Contar aqui não depende de nada e não pode
  -- dessincronizar: quem desenha o botão é quem o soma.
  encaixe.botoes = (encaixe.botoes or 0) + 1
  local x, y = ImGui.GetCursorScreenPos(ctx)
  x, y = math.floor(x), math.floor(y)
  local dl = ImGui.GetWindowDrawList(ctx)

  ImGui.InvisibleButton(ctx, '##tb_' .. kind, D, D)
  local hovered = ImGui.IsItemHovered(ctx)
  local clicked = ImGui.IsItemClicked(ctx)

  -- 'cc': `ativo` aqui significa "CC lanes ocultas agora", não "botão
  -- pressionado" — o aviso já é o risco em cima do ícone (ver abaixo),
  -- então o fundo fica neutro em vez de ganhar o destaque azul.
  local fundo = Theme.UI.panel
  if ativo and kind ~= 'cc' then
    fundo = (kind == 'rec') and Theme.UI.rec or Theme.UI.accent
  elseif hovered then
    fundo = Theme.UI.panelHover
  end

  ImGui.DrawList_AddRectFilled(dl, x, y, x + D, y + D, fundo, 7)
  ImGui.DrawList_AddRect(dl, x, y, x + D, y + D, 0x00000055, 7)

  local cor = 0xE6E9EFFF
  if kind == 'rec' and not ativo then cor = 0xE5484DFF end
  if kind == 'alerta' then cor = Theme.UI.warn end

  local cx, cy = x + D * 0.5, y + D * 0.5

  -- TODOS OS ÍCONES SÃO IMAGEM.
  --
  -- Eram desenhados aqui com primitivas (AddTriangleFilled, AddLine,
  -- AddRectFilled) e saíam serrilhados na tela — play, desfazer, refazer
  -- e próxima região eram os piores, justamente os de ponta aguda ou
  -- feitos de linha mais triângulo emendados. O ImGui suaviza cada
  -- primitiva empurrando as arestas 0,5px para fora, o que numa junção
  -- de duas primitivas não fecha.
  --
  -- Agora seguem a MESMA rota que o release e a engrenagem já usavam, e
  -- que os 101 botões do .form usam: máscara -> PNG -> textura (ver
  -- ui/glyphs.lua e ui/icon_cache.lua). As bordas são calculadas uma vez,
  -- fora do REAPER, com superamostragem — não a cada quadro pelo ImGui.
  -- 'settings' desenha o Glyphs.gear: o nome do botão e o do desenho
  -- são diferentes de propósito, um é a função e o outro é a figura.
  local glyph = Glyphs[(kind == 'settings') and 'gear' or kind]
  local img = glyph and IconCache.mono(ImGui, ctx, kind, glyph, cor)

  if img then
    -- SEMPRE NO TAMANHO NATURAL DA MÁSCARA, 1 pixel para 1 pixel.
    --
    -- Release e engrenagem vieram do usuário com 16px; os gerados têm
    -- 22. Houve uma tentativa de ampliar aqueles para 20 só para
    -- casarem de tamanho — e o resultado foi exatamente o que uma
    -- escala de 1,25x faz: os dois ficaram visivelmente embaçados ao
    -- lado dos demais, que estavam nítidos. Diferença de tamanho
    -- incomoda menos que falta de nitidez, e é reversível: bastam PNGs
    -- de 22px para eles ficarem do tamanho dos outros SEM ampliação.
    local lado = glyph.lado
    local ix = math.floor(cx - lado * 0.5)
    local iy = math.floor(cy - lado * 0.5)
    ImGui.DrawList_AddImage(dl, img, ix, iy, ix + lado, iy + lado)

    -- CC lanes ocultas agora: risco por cima, o mesmo sentido do "olho
    -- riscado" de outros programas.
    if kind == 'cc' and ativo then
      ImGui.DrawList_AddLine(dl, cx - 9, cy + 9, cx + 9, cy - 9, cor, 2.4)
    end
  else
    -- Sem imagem o botão ficaria VAZIO e pareceria quebrado. Isto só
    -- acontece num ReaImGui sem CreateImage nenhum — o mesmo caso em
    -- que os ícones do .form também somem. Um disco não é o desenho
    -- certo, mas mantém o botão visível, clicável e com a dica.
    ImGui.DrawList_AddCircleFilled(dl, cx, cy, 7, cor)
  end

  -- DISTINTIVO no canto: um número pequeno sobre o botão.
  --
  -- Nasceu para os botões marcados esperando o play, que antes eram um
  -- texto solto na barra ("3 botão(ões) marcado(s) para a abertura").
  -- Depois que a barra passou a alinhar as Configurações à direita, esse
  -- texto era desenhado DEPOIS delas e ficava fora da janela — na tela
  -- sobrava só o "3", sem explicação nenhuma. No canto do REC ele fica
  -- junto do que descreve, e o texto inteiro vai para a dica.
  if distintivo then
    local bx, by = x + D - 6, y + 6
    ImGui.DrawList_AddCircleFilled(dl, bx, by, 8, Theme.UI.bg)
    ImGui.DrawList_AddCircleFilled(dl, bx, by, 6.5, Theme.UI.warn)
    local wT, hT = ImGui.CalcTextSize(ctx, distintivo)
    ImGui.DrawList_AddText(dl, math.floor(bx - wT * 0.5),
      math.floor(by - hT * 0.5), 0x412402FF, distintivo)
  end

  if hovered and textoDica then dicaSe( textoDica) end
  return clicked
end

--- Liga a gravação e começa a tocar, como o REC do REAPER.
--- Preparar a música, num ponto de desfazer só.
--
--  É a maior escrita que o programa faz de uma vez: cria o item MIDI da
--  música e escreve o release e o estado inicial. A criação do item
--  ficava fora de qualquer bloco — Timeline.prepareRegion não abre um, e
--  o Timeline.write que vem depois abre só o dele.
--
--  Embrulhado AQUI, na ação do usuário, e não na primitiva: a mesma
--  prepareRegion é chamada ao começar uma gravação, e embrulhá-la lá
--  dentro abria um ponto de desfazer no meio da gravação — foi o teste
--  "nenhum ponto de desfazer fechado durante a gravação" que apontou.
local function prepareSong(silent)
  return Timeline.editarItens('LumiBridge: preparar a música', function()
    return prepareSongCru(silent)
  end)
end

local function startRecording()
  -- O REC NÃO ESCREVE NADA.
  --
  -- Ele apenas passa a ouvir: a interface segue mostrando e enviando o
  -- que já está gravado, e só o que VOCÊ clicar é escrito, no instante
  -- do clique. Sem isto, apertar REC no meio de uma música já pronta
  -- criava notas do nada — release, estado inicial, retomada de linhas.
  --
  -- Quem escreve o release e o estado inicial é o botão "Preparar", que
  -- é um ato explícito de começar uma música do zero.
  -- A sessão de desfazer abre ANTES do preparo automático: assim o
  -- preparo e a gravação viram UM único Ctrl+Z, e não dois.
  Timeline.resetLive()
  Timeline.clearTails()
  Timeline.beginSession()
  manualCursor = {}  -- nenhum fader é "seu" ainda nesta gravação nova

  -- PREPARO AUTOMÁTICO.
  --
  -- Se a região ainda não tem programação, o REC faz o mesmo que o botão
  -- "Preparar": item do tamanho da região, Release All no primeiro
  -- quadradinho e os faders em 100% nas pontas. Ter de lembrar de
  -- preparar antes de gravar era um passo manual à toa.
  --
  -- Com programação, não se toca em nada: o REC só ouve.
  local musicaJaProgramada = false
  if region and Timeline.isReady() then
    -- A decisão olha o QUE ESTÁ NA TIMELINE, não uma lembrança de já
    -- ter preparado nesta sessão.
    --
    -- Antes bastava ter preparado uma vez para o preparo nunca mais
    -- rodar naquela música — mesmo depois de um Ctrl+Z ter apagado
    -- tudo. O resultado era gravar numa região sem release e sem os
    -- pontos de fader.
    local jaTem = Timeline.countNotesIn(region.startTime, region.endTime)
    if jaTem == 0 and preparo.auto then
      prepareSong(true)
      log('preparo automático ao gravar')
    elseif jaTem == 0 then
      -- Preparo automático desligado: só garante o item onde escrever.
      -- Sem release, sem abertura, sem pontos de fader — a música fica
      -- exatamente como você a deixar.
      ensureItem()
      log('região vazia, preparo automático desligado')
    else
      ensureItem()
      musicaJaProgramada = true
    end
  else
    ensureItem()
  end

  if recorder then Recorder.setGrid(recorder, Timeline.projectGrid()) end

  recording = true
  log(('REC ligado em %s'):format(Transport.formatTime(Transport.position())))

  -- OS BOTÕES MARCADOS ENTRAM NA MÚSICA JÁ PROGRAMADA.
  --
  -- Numa região vazia, o preparo acima escreve o estado inicial. Numa
  -- região JÁ PROGRAMADA o REC "só ouve" — e era aí que a alteração se
  -- perdia: parado, clicar apenas MARCA o botão (ver record()), e se
  -- nada aplica essa marca ao gravar, o clique não vira nada. O sintoma
  -- é o relatado: posicionar o cursor no início, clicar noutra cor,
  -- gravar, e a cor antiga continuar valendo.
  --
  -- Recorder.punchIn existia e estava testada isoladamente desde
  -- sempre, mas NUNCA era chamada pela janela — a mesma falha que
  -- originou o tests/test_window_record.lua (ver o cabeçalho dele).
  -- Testar a peça não prova que ela está ligada.
  -- SÓ O QUE DIFERE do que já está gravado naquele ponto.
  --
  -- A regra "numa música já programada o REC não escreve nada" existe
  -- para o REC no meio da música não inventar notas — e continua
  -- valendo: se o que está marcado na tela é o que já soa ali, nada é
  -- escrito. Comparar contra o que soa é o que separa "o usuário mudou
  -- de ideia" de "o usuário só apertou REC".
  if musicaJaProgramada and recorder and session and Timeline.isReady() then
    local rc = context()
    local soando = Timeline.soundingAt(rc.time)

    local mudados, alvos = {}, {}
    for _, el in ipairs(layout and layout.elements or {}) do
      -- `espelho.marcados`, não `session.active`: aceso na tela pode
      -- ser só o espelho mostrando o que já está gravado ali.
      if el.tag and espelho.marcados[el.tag]
         and session.active[el.tag] and not session.faderTags[el.tag] then
        local propria
        for _, cmd in ipairs(el.commands or {}) do
          if (cmd.status & 0xF0) == 0x90 then propria = cmd.data1 break end
        end
        -- Já está soando essa altura? Então não mudou nada.
        if propria and not soando[propria] then
          mudados[#mudados + 1] = el
          alvos[propria] = true
          for p in pairs(el.rivalPitches or {}) do alvos[p] = true end
        end
      end
    end

    -- FADERES MOVIDOS PARADO: o valor da tela passa a valer daqui.
    --
    -- Um fader não "soa" como uma nota, então a comparação dos botões não
    -- serve: o que decide é se a posição na tela é diferente do que a
    -- automação diz naquele ponto. Se for, escreve um ponto aqui — e a
    -- rampa que vinha antes termina nele, que é o que "sobrescrever a
    -- partir do cursor" significa numa automação.
    local ccAgora = Timeline.ccValuesAt(rc.time)
    local pontos = {}
    for tag in pairs(espelho.marcados) do
      if session.faderTags[tag] then
        local el = session.byTag[tag]
        local cc, canal
        for _, cmd in ipairs(el and el.commands or {}) do
          if (cmd.status & 0xF0) == 0xB0 then
            cc, canal = cmd.data1, cmd.channel
            break
          end
        end
        local novo = Session.faderCC(session, tag)
        if cc and novo ~= (ccAgora[cc] or -1) then
          pontos[#pontos + 1] = { kind = 'cc', channel = canal or 1, cc = cc,
                                  value = novo, qn = rc.qn }
          log(('%s: %d%% a partir daqui'):format(
            el.text or tostring(tag), math.floor(novo / 127 * 100 + 0.5)))
        end
      end
    end
    if #pontos > 0 then Timeline.write(pontos) end

    -- Consumidas: o que foi marcado já virou nota, e uma segunda
    -- gravação não pode reescrever a mesma coisa de novo.
    espelho.marcados = {}

    if #mudados > 0 then
      -- Corta o que soava ali — a própria altura e as rivais do grupo —
      -- antes de abrir as linhas novas. É o mesmo par de passos que um
      -- clique durante a gravação faz.
      Timeline.truncatePitchesAt(rc.time, alvos)

      local out = Recorder.punchIn(recorder, mudados, rc.qn)
      if #out > 0 then Timeline.write(out) end
      log(('%d controle(s) marcado(s) diferente(s) do gravado: escrito(s)')
        :format(#mudados))
    end
  end

  -- O REC dispara o play junto, como no REAPER.
  if not Transport.isPlaying() then Transport.play() end
end


--- Desfaz ou refaz, e faz a tela acompanhar.
--
--  UM CAMINHO SÓ PARA OS DOIS GESTOS. O botão limpava o índice depois de
--  desfazer; o Ctrl+Z do teclado não. E o projeto era desfeito nos dois
--  casos — só que, sem limpar o índice, a Programação MIDI continuava
--  desenhando o estado ANTIGO: as notas voltavam no REAPER e não na
--  tela. Indistinguível de "o desfazer não funciona", e foi assim que
--  ele foi relatado.
--
--  O índice guarda notas e CC lidos do item, e desfazer recria os itens:
--  os endereços de take que ele guarda deixam de valer. Limpá-lo obriga
--  a releitura, e a releitura é o que traz o estado novo para a lista, o
--  espelho e a onda.
local function desfazerOuRefazer(refazer)
  -- PRIMEIRO A NOSSA PILHA, e só depois a do REAPER.
  --
  -- Cada edição feita na Programação MIDI guarda o antes e o depois dos
  -- itens que mexeu (ver Timeline.editar). Desfazer é voltar uma dessas
  -- fotos — uma edição, um passo, sem depender de o REAPER ter ou não
  -- registrado o bloco. Era aí que estava o estrago: um bloco descartado
  -- em silêncio fazia o Ctrl+Z acertar o ponto anterior, que logo depois
  -- de gravar é a gravação inteira.
  --
  -- A pilha do REAPER continua valendo para o que é dele: a gravação e o
  -- preparo da música. Ela entra quando a nossa acaba — que é justamente
  -- onde o usuário espera: desfiz minhas edições, o próximo Ctrl+Z
  -- desfaz a gravação.
  local temNosso = refazer and Timeline.podeRefazerEdicao()
                            or (not refazer and Timeline.podeDesfazerEdicao())
  if temNosso then
    local feito, perdido = refazer and Timeline.refazerEdicao()
                                    or Timeline.desfazerEdicao()
    faixas.at = 0
    faixas.selCC = {}
    faixas.sel = nil
    if feito then
      log((refazer and 'refeito: ' or 'desfeito: ') .. tostring(feito))
    else
      log(('não consegui %s "%s": os itens não estão mais como estavam')
        :format(refazer and 'refazer' or 'desfazer', tostring(perdido)))
    end
    return
  end

  -- O QUE VAI SER DESFEITO, ANTES DE DESFAZER.
  --
  -- Sem passo nosso, o gesto cai na pilha do REAPER — onde moram a
  -- gravação, o preparo e tudo o que foi feito no arranjo. Se o topo for
  -- nosso (a gravação), desfaz direto, que é o esperado. Se não for, o
  -- gesto vira uma pergunta com o nome do que será desfeito: é a única
  -- coisa que se pode fazer sobre uma pilha que não é nossa.
  local rotulo = refazer and Transport.redoLabel() or Transport.undoLabel()
  local nosso = rotulo and rotulo:find('LumiBridge', 1, true) ~= nil

  local function aplicar()
    if refazer then Transport.redo() else Transport.undo() end
    Timeline.invalidateIndex()
    -- O REAPER acabou de trocar o projeto debaixo das nossas fotos: as
    -- que sobrassem descreveriam itens de outro estado.
    Timeline.esquecerEdicoes()
    faixas.at = 0      -- remonta a lista já no próximo quadro
    faixas.selCC = {}  -- a seleção era de pontos que podem não existir mais
    faixas.sel = nil
    log((refazer and 'refeito: ' or 'desfeito: ') .. tostring(rotulo))
  end

  if nosso or not rotulo then return aplicar() end

  confirmar = {
    titulo = refazer and 'Refazer isto?' or 'Desfazer isto?',
    texto = ('O próximo passo da pilha do REAPER não é uma edição do\n'
             .. 'LumiBridge:\n\n    %s\n\n'
             .. 'Isso acontece quando a última edição não gerou ponto de\n'
             .. 'desfazer — e aí este gesto desfaz o que veio ANTES dela,\n'
             .. 'que pode ser uma gravação inteira.'):format(tostring(rotulo)),
    rotulo = refazer and 'Refazer' or 'Desfazer',
    acao = aplicar,
  }
end

--- Escreve na timeline os gestos de fader que terminaram.
--
--  @param forcar  ignora a espera e o botão do mouse, e descarrega TUDO
--                 o que estiver pendente. Usado ao PARAR A GRAVAÇÃO.
--
--  POR QUE O `forcar` EXISTE: um gesto só é escrito 0,35s depois de
--  parar de chegar leitura (GESTO_TIMEOUT), para que giros seguidos da
--  roda contem como um movimento só. Mas parar a gravação dentro dessa
--  janela — ou com o fader ainda segurado — descartava o movimento
--  inteiro: o `faderMov` é zerado no começo da gravação seguinte e
--  ninguém nunca escrevia aquele trecho. Era o "às vezes não grava o
--  CC": não é aleatório, é sempre que o stop chega antes da espera.
local function descarregarGestos(forcar)
  -- FIM DO GESTO.
  --
  -- Enquanto o botão do mouse está segurando, o gesto continua. Com a
  -- roda não há botão: o gesto termina quando param de chegar leituras.
  --
  -- Sem essa espera, cada giro da roda virava um gesto isolado e a
  -- automação enchia de pontos soltos, em vez de uma curva do início ao
  -- fim do movimento.
  local agora = reaper.time_precise and reaper.time_precise() or 0
  -- Nome próprio, e não `arrastando`: aquele é o arrasto da BARRA DE
  -- TÍTULO (hoje chrome.arrastando), e ter os dois com o mesmo nome já
  -- fez uma renomeação em massa trocar um pelo outro.
  local mouseSegurando = ImGui.IsMouseDown(ctx, 0)

  if next(faderMov) and (forcar or not mouseSegurando) then
    for tag, mov in pairs(faderMov) do
      if not forcar and agora - (mov.ultimo or 0) < GESTO_TIMEOUT then goto continuar end
      if recording and recorder and Timeline.isReady() and #mov.pontos > 0 then
        -- POLIMENTO (Douglas-Peucker): as dezenas de leituras viram só os
        -- pontos que definem a FORMA do gesto — os que se afastam da reta
        -- entre vizinhos ficam, o resto (tremor de mão) é descartado.
        -- Um movimento que sobe, para num valor e desce (ou vice-versa)
        -- preserva esse ponto do meio, mesmo sem soltar o botão nele.
        -- A curva slow start/end liga um ponto ao outro com uma rampa em
        -- S, e é ela que devolve o movimento natural.
        local finais = Curve.polish(mov.pontos, recorder.gridQN)
        local escritas = {}
        for _, ponto in ipairs(finais) do
          for _, it in ipairs(Recorder.fader(recorder, mov.element,
                                             ponto.qn, ponto.value)) do
            escritas[#escritas + 1] = it
          end
        end

        -- PUNCH-IN DE CC: os pontos que já existiam nesse trecho perdem
        -- para o movimento novo — mesmo espírito do punch-in de nota
        -- (M5.3). Nada antes do início do gesto é tocado.
        --
        -- "Seu até o Stop": se este fader já tinha sido tocado antes
        -- NESTA MESMA gravação, a limpeza começa de onde a anterior
        -- parou (manualCursor), não do início deste gesto — assim
        -- soltar e pegar o fader de novo não deixa um buraco com a
        -- automação antiga sobrevivendo entre as duas vezes. Na
        -- primeira vez, começa no início deste gesto mesmo.
        local apagados = 0
        if #escritas > 0 then
          local primeiro = escritas[1]
          local desde = manualCursor[tag] or mov.pontos[1].qn
          local ate   = mov.pontos[#mov.pontos].qn
          apagados = Timeline.clearCCRange(primeiro.cc, primeiro.channel, desde, ate)
          manualCursor[tag] = ate
        end

        -- O PONTO DO FIM DA MÚSICA acompanha o valor onde o fader parou.
        --
        -- O preparo deixou um ponto no fim com o valor inicial. Sem
        -- atualizá-lo, a automação subiria e depois desceria sozinha
        -- até o fim da música, desfazendo o movimento.
        if region and #finais > 0 then
          local ultimo = finais[#finais].value
          local fimQN = Timeline.timeToQN(region.endTime) - recorder.gridQN
          for _, it in ipairs(Recorder.fader(recorder, mov.element,
                                             fimQN, ultimo)) do
            escritas[#escritas + 1] = it
          end
        end

        if #escritas > 0 then Timeline.write(escritas) end
        log(('fader %s: %s%s'):format(mov.element.text or tag,
          Curve.describe(#mov.pontos, #finais),
          apagados > 0 and (' | %d ponto(s) antigo(s) substituído(s)'):format(apagados) or ''))
      end
      faderMov[tag] = nil
      ::continuar::
    end
  end
end

local function stopRecording()
  -- Registra SEMPRE, mesmo sem linha aberta: saber onde a gravação
  -- terminou é o dado mais importante para comparar com o Piano Roll.
  log(('REC desligado em %s  (%s)')
    :format(Transport.formatTime(Transport.position()),
            quadro.ultimaQN and ('%.2f QN tocados'):format(quadro.ultimaQN) or 'sem posição'))

  -- DESCARREGA OS GESTOS DE FADER ANTES DE QUALQUER OUTRA COISA.
  --
  -- Precisa vir com `recording` AINDA LIGADO: a escrita do gesto passa
  -- por `if recording and recorder and Timeline.isReady()`, e desligar
  -- antes descartaria em silêncio o movimento pendente — que é
  -- justamente o que se quer salvar aqui.
  descarregarGestos(true)

  recording = false
  meus = {}          -- terminou a gravação: a timeline volta a mandar
  -- As marcas eram desta gravação. Mantê-las faria a PRÓXIMA
  -- reescrever de novo o que já foi escrito aqui.
  espelho.marcados = {}
  closeOpenLines()

  -- DEVOLVE AS CAUDAS: os pedaços das notas antigas que iam além do
  -- trecho regravado voltam a valer daqui para a frente.
  --
  -- É o que faz a programação anterior continuar depois do stop. Sem
  -- isto, trocar uma cor no meio e parar deixava o resto da música
  -- daquele controle vazio.
  if Timeline.isReady() then
    local fim = quadro.ultimaQN or (recorder and Timeline.timeToQN(Transport.position()))
    if fim then
      local n = Timeline.restoreTails(fim)
      if n > 0 then
        -- DIZ ATÉ ONDE cada um foi devolvido.
        --
        -- Dizia só quantos. "Gravei dez segundos e ele preencheu a
        -- música inteira" pode ser a gravação tendo crescido demais ou
        -- uma cauda antiga voltando até o fim, e na tela as duas são a
        -- mesma barra comprida. Com os números, o registro separa as
        -- duas em uma leitura.
        local partes = {}
        for _, c in ipairs(Timeline.ultimasCaudas or {}) do
          partes[#partes + 1] = ('nota %s ch%s %s -> %s'):format(
            tostring(c.pitch), tostring(c.canal),
            Transport.formatTime(Timeline.qnToTime(c.deQN)),
            c.ateQN and Transport.formatTime(Timeline.qnToTime(c.ateQN))
                    or '?')
        end
        log(('%d trecho(s) anterior(es) devolvido(s)%s'):format(n,
          #partes > 0 and (': ' .. table.concat(partes, ' | ')) or ''))
      end

      -- FECHA A LINHA DE CADA FADER MANUAL, na posição do Stop.
      --
      -- Um fader tocado durante a gravação fica seu até aqui (ver
      -- manualCursor, no fechamento do gesto acima). Sem este ponto
      -- final, o trecho entre o seu último toque e o instante em que
      -- você apertou Stop ficaria com a automação antiga sobrevivendo
      -- — exatamente o buraco que essa funcionalidade existe pra
      -- fechar.
      if recorder and session and next(manualCursor) then
        local fechados = 0
        for tag, desde in pairs(manualCursor) do
          local e = session.byTag[tag]
          if e and desde < fim then
            local valor = math.floor(Session.faderValue(session, e) * 127 + 0.5)
            local escritas = Recorder.fader(recorder, e, fim, valor)
            if #escritas > 0 then
              Timeline.clearCCRange(escritas[1].cc, escritas[1].channel, desde, fim)
              Timeline.write(escritas)
              fechados = fechados + 1
            end
          end
        end
        if fechados > 0 then
          log(('%d fader(es) manual(is) fechado(s) no stop'):format(fechados))
        end
      end
    end
  end
  manualCursor = {}
  Timeline.endSession(region
    and ('LumiBridge: gravação em %s'):format(region.name)
    or 'LumiBridge: gravação')
end

local function drawTransportBar()
  local playing = Transport.isPlaying()

  --- Onde o cursor de layout está, na horizontal. Zero se esta geração
  --  do ReaImGui não tiver a função.
  --
  --  Dentro da função de propósito: só ela mede, e o corpo do módulo tem
  --  teto de 200 locais. Um ajudante em vez de repetir o par
  --  Compat.get + pcall nos quatro lugares que precisam medir.
  --  POR GetCursorScreenPos, e não por GetCursorPosX.
  --
  --  GetCursorPosX não existe nesta instalação — e como o ajudante
  --  devolvia nil nesse caso, a repartição do espaço nunca acontecia: a
  --  folga ficava no mínimo de 10px e todo o excedente ia parar num vão
  --  único antes do último bloco. Era o alinhamento que não vinha.
  --
  --  GetCursorScreenPos é usada às dezenas neste arquivo e funciona aqui.
  --  Ela devolve coordenada de TELA, não de janela — e não faz diferença
  --  nenhuma, porque tudo o que se faz com ela aqui é subtrair duas
  --  leituras. A diferença é a mesma nos dois sistemas.
  --
  --  Devolve NIL quando não dá para medir, e não zero: zero é uma medida
  --  plausível (é o começo da linha), e com ele a conta do espaço que
  --  sobra dá a janela inteira.
  local function xAtual()
    -- Duas fontes, nesta ordem: a precisa e a que sempre existe.
    -- TRÊS FONTES. GetCursorPos é a que faltava: existe onde
    -- GetCursorPosX não existe, devolve o par (x, y) em coordenada de
    -- janela, e o primeiro valor é o que se quer. Só se usam DIFERENÇAS
    -- entre duas leituras, então tanto faz qual sistema de coordenadas
    -- responde — desde que seja o mesmo nas duas pontas, e é, porque a
    -- ordem de tentativa não muda no meio do quadro.
    for _, nome in ipairs({ 'GetCursorPosX', 'GetCursorPos',
                            'GetCursorScreenPos' }) do
      local fn = Compat.get(ImGui, nome)
      if fn then
        local ok, v = pcall(fn, ctx)
        if ok and type(v) == 'number' then return v end
      end
    end
    return nil
  end

  -- Medida ANTES de desenhar qualquer botão: é a largura da janela
  -- inteira, a partir da margem esquerda da linha — usada mais abaixo
  -- pra empurrar alerta+configurações pro canto direito de verdade, em
  -- vez de só "o último botão em fileira", que sobra longe da borda
  -- numa janela mais larga que a soma dos botões.
  -- RECUO PRÓPRIO, agora que a janela não tem espaçamento nenhum.
  --
  -- Sem espaçamento em volta, a barra de título e o painel do .form
  -- colam na borda como devem — mas os botões do transporte colariam
  -- também, e botão encostado no canto da tela é desconfortável de
  -- acertar e feio de ver. A folga passa a ser pedida aqui, por quem
  -- precisa dela.
  ImGui.Dummy(ctx, 1, 3)
  -- O Dummy mais o espaçamento entre itens somam a margem: é por isso
  -- que se desconta M.espaco aqui.
  ImGui.Dummy(ctx, M.margem - M.espaco, 1)
  ImGui.SameLine(ctx)
  -- ONDE A LINHA COMEÇA. O quanto já foi gasto até o combo sai da
  -- DIFERENÇA entre este ponto e aquele — nunca do valor absoluto do
  -- cursor, que depende de o que veio antes na janela.
  -- CONTAGEM DO QUADRO. `botoes` é somado dentro de transportButton;
  -- `extra` recebe o que não é botão (o campo da música, o relógio, os
  -- respiros fixos), cada um com o espaçamento que vem depois dele.
  encaixe.botoes, encaixe.extra = 0, 0
  local function ocupa(w) encaixe.extra = encaixe.extra + (w or 0) + M.espaco end

  local xInicio = xAtual() or 0
  -- A ÂNCORA É AQUI, no começo da linha.
  --
  -- Ela era tomada lá adiante, DEPOIS de play/pause/stop/começo/rec já
  -- desenhados: a conta do espaço ocupado nascia uns duzentos pixels
  -- curta, e a repartição saía errada por essa diferença todo quadro.
  encaixe.barraX0 = xInicio

  -- A LARGURA DA JANELA, não o espaço que sobra a partir do cursor.
  --
  -- Era GetContentRegionAvail, medido AQUI — e aqui já passou o recuo da
  -- esquerda, então o valor era menor que a janela. O grupo da direita é
  -- posicionado por um deslocamento a partir do INÍCIO da linha, então
  -- essa diferença virava deslocamento a mais e empurrava o último botão
  -- para fora: o de Configurações aparecia cortado pela borda.
  --
  -- Medir a janela é o que não depende de onde o cursor está.
  local larguraJanela = ImGui.GetWindowSize(ctx)
    or ImGui.GetContentRegionAvail(ctx)

  if transportButton('play', playing, 'Play / Stop   Espaço') then
    Transport.togglePlayStop()
  end
  ImGui.SameLine(ctx)
  if transportButton('pause', Transport.isPaused(),
      'Pause   Enter') then
    Transport.togglePlayPause()
  end
  ImGui.SameLine(ctx)
  if transportButton('stop', false, 'Stop') then Transport.stop() end

  -- AO COMEÇO DA MÚSICA. Não é "região anterior": é o batente desta.
  -- Programar é voltar ao início dezenas de vezes por música, e isso era
  -- feito arrastando o cursor na onda ou pelo REAPER.
  ImGui.SameLine(ctx)
  if transportButton('inicio', false, 'Ao começo da música   ←') then
    if region then saltarPara(region.startTime, false) end
  end
  -- BOTÕES MARCADOS ESPERANDO O PLAY — o estado inicial da música.
  --
  -- Só faz sentido PARADO: é o momento em que se escolhe com o que a
  -- música começa. Tocando ou gravando o número some, porque ali o
  -- estado da tela já é o da execução, não uma intenção.
  -- A dica LISTA o que está marcado, não só conta.
  --
  -- Um número sozinho diz que há três coisas, e não quais — e é
  -- justamente "quais" que se precisa saber antes de gravar a abertura.
  -- Os faders entram com a POSIÇÃO em porcentagem, que é a informação
  -- deles equivalente a "aceso" num botão.
  local marcados, nomes, faders = 0, {}, {}
  if not playing and not recording and session and layout then
    for _, el in ipairs(layout.elements) do
      if el.tag then
        if session.faderTags[el.tag] then
          local v = Session.faderValue(session, el)
          if v then
            faders[#faders + 1] = ('   %s  %d%%')
              :format(el.text ~= '' and el.text or ('fader ' .. el.tag),
                      math.floor(v * 100 + 0.5))
          end
        elseif session.active[el.tag] then
          marcados = marcados + 1
          nomes[#nomes + 1] = '   ' ..
            (el.text ~= '' and el.text or ('controle ' .. el.tag))
        end
      end
    end
  end

  local dicaRec = 'Gravar   Ctrl+R'
  if marcados > 0 then
    dicaRec = dicaRec .. ('\n\n%d botão(ões) marcado(s) para a abertura:\n%s')
      :format(marcados, table.concat(nomes, '\n'))
      .. '\n\nAo gravar, a música larga com eles acesos.'
  end
  if #faders > 0 then
    dicaRec = dicaRec .. '\n\nFaders:\n' .. table.concat(faders, '\n')
  end

  ImGui.SameLine(ctx)
  if transportButton('rec', recording, dicaRec,
      marcados > 0 and tostring(marcados) or nil) then
    if recording then stopRecording() else startRecording() end
  end

  -- QUATRO BLOCOS, e o que sobra é REPARTIDO entre eles.
  --
  --   1  transporte      play, pause, stop, rec, começo, zoom
  --   2  música          navegação e o campo com o nome
  --   3  ferramentas     preparar, apagar, desfazer, refazer, release
  --   4  telas           programação MIDI, avisos, configurações
  --
  -- Era 2% da largura, preso entre 10 e 48. Numa janela larga isso
  -- travava em 48 e todo o espaço que sobrava ia parar num vão único
  -- antes do bloco 4 — os três primeiros ficavam amontoados à esquerda,
  -- que é o oposto de "ajustar quando a tela cresce".
  --
  -- A CONTA NÃO MEDE MAIS NADA, e é essa mudança que a faz funcionar.
  --
  -- Duas versões dela dependiam de saber onde o cursor de layout está.
  -- A primeira usava GetCursorPosX, que não existe na instalação do
  -- usuário. A segunda caía para GetCursorScreenPos — e a barra
  -- continuou sem repartir, com o teste verde dos dois lados. Depois de
  -- três rodadas assim, a dependência é que estava errada: quem desenha
  -- uma barra de largura conhecida não precisa perguntar a ninguém
  -- quanto ela ocupa.
  --
  -- Agora o conteúdo é CONTADO por quem desenha. transportButton soma
  -- um a `encaixe.botoes`; o campo da música, o relógio e os respiros
  -- fixos passam por `ocupa`. Não há como dessincronizar sem mexer no
  -- mesmo lugar que desenha.
  --
  -- A CONTA. Da margem esquerda até o começo do bloco 4 (pinado à
  -- direita) há L pixels. Os blocos 1 a 3 ocupam `conteudo` — cada item
  -- mais o espaçamento que vem depois dele —, e entre eles vão duas
  -- folgas de `respiro`, cada uma custando respiro + 2 espaçamentos.
  -- Igualando o vão que sobra às outras duas:
  --
  --      respiro = (L - conteudo - 3 * espaco) / 3
  --
  -- Um quadro de atraso, porque a contagem termina depois de desenhar —
  -- e a trinta quadros por segundo ninguém vê.
  --
  -- O mínimo de 10 continua: repartir espaço que não existe encavalaria
  -- os blocos, e aí o combo da música é quem cede (ver adiante).
  local respiro = 10
  if encaixe.barraConteudo and larguraJanela then
    local L = larguraJanela - (encaixe.barraCluster or 75) - M.margem * 2
    local alvo = math.floor((L - encaixe.barraConteudo - M.espaco * 3) / 3)
    if alvo > respiro then respiro = alvo end
  end
  encaixe.respiro = respiro    -- para o diagnóstico e para os testes

  -- A LUPA, LOGO DEPOIS DO REC e sempre na tela.
  --
  -- Antes ela só aparecia com zoom, e um botão que vai e vem move os
  -- vizinhos de lugar — o alvo muda de posição justamente quando se
  -- aprendeu onde ele estava. Agora fica sempre, apagada: apagada diz
  -- "não há zoom", acesa diz "há zoom, e daqui se desfaz". O estado vira
  -- informação, em vez de ausência.
  --
  -- Junto do transporte porque o zoom é da LINHA DO TEMPO: vale para a
  -- onda e para a Programação MIDI de uma vez, já que as duas mostram o
  -- mesmo trecho.
  ImGui.SameLine(ctx)
  do
    local temZoom = (faixas.vDe ~= nil) or ((faixas.escalaV or 1) ~= 1)
    if transportButton('lupa', temZoom,
        temZoom and 'Música inteira   desfaz o zoom'
        or 'Zoom: roda do mouse sobre a onda ou a programação') then
      if temZoom then
        faixas.vDe, faixas.vAte = nil, nil
        faixas.escalaV = 1
        encaixe.w = 0
      end
    end
  end

  -- Fim do bloco 1, começo do 2.
  ImGui.SameLine(ctx)
  ImGui.Dummy(ctx, respiro, 1)

  -- O RELÓGIO É OPCIONAL, e vem desligado.
  --
  -- O REAPER já mostra a posição, em letra maior e sempre à vista. Aqui
  -- ele custava uns 90px na barra mais disputada da janela para repetir
  -- o que está logo ali — e a onda, com o cursor correndo em cima dela,
  -- responde "onde estou" melhor que um número.
  if opcoes.relogio then
    ImGui.SameLine(ctx)
    ImGui.Dummy(ctx, 6, 1)
    ocupa(6)
    ImGui.SameLine(ctx)
    local comFonte = Theme.pushFont(ImGui, ctx, state.fonts, 20)
    local texto = Transport.formatTime(Transport.position())
    ImGui.Text(ctx, texto)
    local larguraRelogio = ImGui.CalcTextSize(ctx, texto)
    if comFonte then ImGui.PopFont(ctx) end
    ocupa(larguraRelogio or 70)
  end

  ImGui.SameLine(ctx)
  ImGui.Dummy(ctx, 6, 1)
  ocupa(6)
  ImGui.SameLine(ctx)
  if opcoes.regioes and transportButton('prev', false, 'Música anterior') then
    local alvo
    for _, rg in ipairs(regions) do
      if rg.startTime < Transport.position() - 0.05 then alvo = rg end
    end
    if alvo then
      region = alvo
      regionPinned = true
      Waveform.reset()
      Transport.gotoRegion(alvo, opcoes.repetir)
    end
  end
  ImGui.SameLine(ctx)
  if opcoes.regioes and transportButton('next', false, 'Próxima música') then
    for _, rg in ipairs(regions) do
      if rg.startTime > Transport.position() + 0.05 then
        region = rg
        regionPinned = true
        Waveform.reset()
        Transport.gotoRegion(rg, opcoes.repetir)
        break
      end
    end
  end

  ImGui.SameLine(ctx)

  -- ALTURA IGUAL À DOS BOTÕES. O combo nasce com a altura de uma linha
  -- de texto mais o espaçamento padrão — bem mais baixo que os 34px dos
  -- botões ao lado, e a fileira ficava desalinhada. O espaçamento
  -- vertical é empurrado só para este item, com o valor que sobra até
  -- os 34, e desempilhado logo abaixo.
  local nPadCombo = 0
  do
    local idPad = Compat.const(ImGui, 'StyleVar_FramePadding', nil)
    local _, alturaTexto = ImGui.CalcTextSize(ctx, 'A')
    local folga = math.max(4, math.floor((34 - alturaTexto) * 0.5))
    if idPad and ImGui.PushStyleVar
       and pcall(ImGui.PushStyleVar, ctx, idPad, 9, folga) then
      nPadCombo = 1
    end
  end

  -- LARGO, MAS NÃO TEIMOSO.
  --
  -- Nomes de música são longos, e em 200px quase todos apareciam
  -- cortados — daí os 320. Só que 320 FIXOS não cabem em toda janela: em
  -- tela HD, ou com a janela reduzida, o combo empurrava o grupo da
  -- direita para fora e os ícones sumiam pela borda. Some sem erro
  -- nenhum, que é o pior jeito de sumir.
  --
  -- O combo é a única coisa elástica desta barra: os botões têm tamanho
  -- fixo e o relógio também. Então é ele que cede. Cede até 120px, que
  -- ainda mostra o começo do nome — e abaixo disso o problema deixou de
  -- ser a barra e passou a ser a janela.
  do
    -- Compat.get, e não acesso direto: o shim do ReaImGui LANÇA ERRO num
    -- campo inexistente, então `ImGui.GetCursorPosX and ...` derrubaria o
    -- script justamente na versão que não a tem.
    local usadoAntes = M.margem + ((xAtual() or xInicio) - xInicio)
    -- O grupo da direita no seu pior caso (com o alerta), mais as duas
    -- folgas e o espaço entre o combo e ele.
    local reservaDireita = 3 * M.botao + 2 * M.espaco + M.margem
                           + M.espaco * 2 + respiro
    local cabe = (larguraJanela or 0) - usadoAntes - reservaDireita
    local larguraCombo = math.max(120, math.min(320, cabe))
    ImGui.SetNextItemWidth(ctx, larguraCombo)
    ocupa(larguraCombo)
  end
  local rotulo = region and region.name or 'sem região'
  local comboAberto = ImGui.BeginCombo(ctx, '##regiao', rotulo)
  -- ABRIU AGORA? O foco do teclado vai para a busca uma única vez, no
  -- quadro da abertura. Pedir foco todo quadro prenderia o cursor lá e
  -- nenhum outro campo da janela poderia ser digitado.
  encaixe.comboNovo = comboAberto and not encaixe.comboAberto
  encaixe.comboAberto = comboAberto
  if nPadCombo > 0 then pcall(ImGui.PopStyleVar, ctx, nPadCombo) end
  dica('Música em que se está trabalhando. Cada música é uma região.\n'
    .. 'Digite para filtrar; a lista está em ordem alfabética.')
  if comboAberto then
    -- CAMPO DE BUSCA. Num repertório de centenas de músicas, rolar a
    -- lista inteira é inviável.
    --
    -- E JÁ COM O CURSOR DENTRO DELE. Abrir a lista e digitar é o gesto
    -- inteiro; ter de clicar no campo antes é um passo que não informa
    -- nada — quem abriu a lista de músicas para digitar já disse o que
    -- queria.
    if encaixe.comboNovo then
      local foco = Compat.get(ImGui, 'SetKeyboardFocusHere')
      if foco then pcall(foco, ctx) end
    end
    ImGui.SetNextItemWidth(ctx, 260)
    local chB, texto = ImGui.InputText(ctx, '##busca', buscaRegiao)
    if ImGui.IsItemActive(ctx) then campoTextoAtivo = true end
    if chB then buscaRegiao = texto end
    ImGui.Separator(ctx)

    local alvo = buscaRegiao:upper()
    local mostradas = 0

    if #regioesOrdenadas == 0 then
      ImGui.Selectable(ctx, 'nenhuma região no projeto', false)
    end

    for _, rg in ipairs(regioesOrdenadas) do
      if alvo == '' or rg.name:upper():find(alvo, 1, true) then
        mostradas = mostradas + 1
        if ImGui.Selectable(ctx, rg.name, region == rg) then
          region = rg
          regionPinned = true      -- daqui em diante, só você troca
          buscaRegiao = ''
          Waveform.reset()
          Transport.gotoRegion(rg, opcoes.repetir)
          log(('música escolhida: %s  (%.1f a %.1f s)')
            :format(rg.name, rg.startTime, rg.endTime))
        end
      end
    end

    if mostradas == 0 and #regioesOrdenadas > 0 then
      ImGui.TextColored(ctx, 0x777F8CFF, 'nenhuma música com esse nome')
    end

    ImGui.EndCombo(ctx)
  end

  -- TRÊS BLOCOS NA BARRA, separados por um respiro.
  --
  --   transporte   play, pause, stop, rec, lupa, começo
  --   música       o campo com o nome, e a navegação entre elas
  --   ferramentas  preparar, apagar, desfazer, refazer, release
  --
  -- Sem a separação são dezesseis botões numa fileira só, e procurar um
  -- deles é varrer a fileira inteira. Com ela, procura-se primeiro o
  -- BLOCO — que é como a mão já pensa: "aquilo do transporte", "aquilo
  -- de desfazer".
  -- Fim do bloco 2, começo do 3.
  ImGui.SameLine(ctx)
  ImGui.Dummy(ctx, respiro, 1)

  -- O REPETIR SAIU DA BARRA e virou ajuste. Ele fica ligado quase
  -- sempre — programar iluminação é repetir o mesmo trecho —, e um botão
  -- para o estado normal é um botão que nunca se aperta, ocupando o
  -- lugar mais disputado da janela.
  ImGui.SameLine(ctx)
  if transportButton('preparar', false,
      'Preparar a música\n\n'
      .. 'Cria o item MIDI do tamanho da região e escreve o Release All\n'
      .. 'no primeiro quadradinho, com os botões marcados no segundo.\n'
      .. 'É o ato de começar uma música do zero.') then
    prepareSong(false)
  end

  -- APAGAR A PROGRAMAÇÃO DESTA MÚSICA: o par do "Preparar".
  --
  -- Fica ao lado dele de propósito — um cria a música do zero, o outro a
  -- devolve ao zero. Procurar o item na track do REAPER para apagar à
  -- mão é sair da tela justamente no momento em que se quer recomeçar.
  --
  -- SEMPRE PERGUNTA. É a única ação daqui que joga trabalho fora de uma
  -- vez, e não há como reconstruí-la a não ser pelo desfazer — que o
  -- usuário pode não pensar em usar a tempo.
  ImGui.SameLine(ctx)
  if transportButton('lixeira', false,
      'Apagar a programação desta música\n\n'
      .. 'Remove os itens MIDI da região na track escolhida.\n'
      .. 'Pergunta antes; dá para desfazer com Ctrl+Z.') then
    if not (region and Timeline.isReady()) then
      log('apagar impedido: sem música escolhida ou sem track')
    else
      -- CONFIRMAÇÃO DESENHADA POR NÓS, não a caixa do sistema.
      --
      -- A janela inteira é desenhada à mão — barra de título, botões,
      -- painel de configurações. Uma caixa cinza do Windows no meio
      -- disso destoa e, pior, aparece fora da janela, às vezes atrás
      -- dela. O estado fica guardado e o desenho acontece no fim do
      -- quadro (ver drawConfirmacao).
      confirmar = {
        titulo = 'Apagar a programação desta música?',
        texto = ('"%s"  ·  %d nota(s) serão removidas.\n\n'
                 .. 'Dá para desfazer com Ctrl+Z.')
                :format(region.name,
                        Timeline.countNotesIn(region.startTime, region.endTime)),
        rotulo = 'Apagar',
        acao = function()
          local n = Timeline.editarItens('LumiBridge: apagar a programação',
            function()
              return Timeline.deleteRegionItems(region.startTime,
                                                region.endTime)
            end)
          quadro.preparada = nil
          faixas.at, faixas.sel = 0, nil
          log(('programação apagada: %s (%d item(ns))')
            :format(region.name, n or 0))
        end,
      }
    end
  end

  --- Segunda linha da dica dos botões desfazer/refazer.
  --
  --  Diz O QUE some ao clicar, e de onde vem: a pilha do editor, que
  --  anda edição por edição, ou a do REAPER, onde estão a gravação e o
  --  preparo. A diferença entre "volta a borda que eu arrastei" e "volta
  --  a gravação inteira" é grande demais para se descobrir depois de
  --  clicar.
  --
  --  DENTRO da função, como xAtual: o corpo do módulo tem teto de 200
  --  locais no Lua e ele já vive na margem.
  local function rotuloDoDesfazer(refazer)
    local nosso = refazer and Timeline.rotuloRefazerEdicao()
                           or Timeline.rotuloDesfazerEdicao()
    if nosso then
      return '\n' .. (nosso:gsub('^LumiBridge: ', ''))
    end
    local deles = refazer and Transport.redoLabel() or Transport.undoLabel()
    return deles and ('\n' .. deles .. '   (do REAPER)') or ''
  end

  -- DESFAZER / REFAZER, à mão. A dica mostra o que será desfeito, para
  -- você conferir antes de clicar — e diz de qual pilha vem: a do editor,
  -- que anda edição por edição, ou a do REAPER, onde mora a gravação.
  ImGui.SameLine(ctx)
  if transportButton('undo', false,
      ('Desfazer   Ctrl+Z%s'):format(
        rotuloDoDesfazer(false))) then
    desfazerOuRefazer(false)
  end

  ImGui.SameLine(ctx)
  if transportButton('redo', false,
      ('Refazer   Ctrl+Shift+Z%s'):format(
        rotuloDoDesfazer(true))) then
    desfazerOuRefazer(true)
  end

  ImGui.SameLine(ctx)
  local clicouRelease = transportButton('release', false,
    'Release: apaga tudo agora, mesmo parado.')
  if clicouRelease and session then
    closeOpenLines()
    local intents = Session.releaseAll(session)
    local viaRelease = false
    for _, intent in ipairs(intents) do
      MidiOut.sendAll(intent.commands)
      if intent.viaRelease then viaRelease = true end
    end
    log(('release %s')
      :format(viaRelease and '(comando da tela)'
              or ('(%d controles)'):format(#intents)))
  end


  -- AVISO DO QUE FALTA — sempre visível, mesmo com o avançado fechado.
  --
  -- Continua aqui, e não escondido no avançado, porque omitir o motivo
  -- de nada funcionar seria pior que o ruído que o modo avançado evita.
  --
  -- Um só botão de alerta: o texto completo está na dica, e o clique
  -- leva à aba que resolve aquele problema, em vez de o usuário ter de
  -- descobrir onde é.
  --
  -- FICA À ESQUERDA do botão de configurações (desenhado antes dele),
  -- a pedido — os dois no canto direito da barra, alerta encostado nele.
  --
  -- A ORDEM IMPORTA: o primeiro da lista é o destino do clique, então
  -- ela vai do mais grave para o menos grave. Áudio fechado vem antes
  -- de tudo porque é o único em que o envio parece ter funcionado do
  -- lado do script e mesmo assim nada chega ao Lumikit.
  local faltando = {}
  local function falta(texto, abaDestino)
    faltando[#faltando + 1] = { texto = texto, aba = abaDestino }
  end

  if MidiOut.enabled and not MidiOut.audioRunning() then
    falta('ÁUDIO FECHADO — o Lumikit não recebe', 'midi')
  end
  if MidiOut.enabled and not MidiOut.isReady() then
    falta('sem porta MIDI', 'midi')
  end
  if not layout then falta('sem tela', 'arquivo') end
  if recording and not Timeline.isReady() then
    falta('sem track', 'gravacao')
  end

  -- Empurra o botão (ou par alerta+botão) pro canto DIREITO de
  -- verdade, a partir da largura da janela medida lá em cima — não só
  -- "o último em fileira", que sobra longe da borda numa janela mais
  -- larga que a soma dos botões. Cada botão é 30px (D, em
  -- transportButton) e o espaçamento entre itens é 7px (ItemSpacing,
  -- ver Theme.push).
  -- O GRUPO INTEIRO ENTRA NA CONTA, um botão a mais inclusive.
  --
  -- Ao acrescentar o botão das faixas eu o desenhei DEPOIS deste
  -- alinhamento sem somá-lo aqui: ele tomou o lugar reservado e empurrou
  -- as Configurações para fora da janela. O botão não "sumiu" — foi
  -- desenhado além da borda direita, exatamente como o "3" perdido no
  -- canto que já tinha acontecido antes por este mesmo motivo.
  --
  -- O CC SAIU DAQUI e virou filtro do cabeçalho da Programação MIDI.
  --
  -- Na barra ele ficava entre botões que agem sobre a JANELA (abrir a
  -- programação, configurações) sendo um filtro do CONTEÚDO de uma
  -- delas. Fazia sentido enquanto o único lugar com CC era o editor do
  -- REAPER; com a lista própria na tela, "esconder os CC" é a mesma
  -- pergunta que "esconder os controles sem uso", e as duas passaram a
  -- morar juntas, ao lado uma da outra.
  --
  -- Ele continua pedindo a mesma coisa ao editor do REAPER: a intenção é
  -- uma só, e vale para as duas telas.
  --
  -- Da esquerda para a direita: faixas, alerta (quando há), configurações.
  -- Configurações no canto e o alerta logo à sua esquerda foi pedido
  -- explícito.
  -- O grupo termina a uma folga da borda direita, igual à da esquerda.
  -- TRÊS BOTÕES, quatro com o alerta: CC, faixas, [alerta], configurações.
  --
  -- Estava reservando um a mais do que desenha. A conta serve para
  -- empurrar o grupo até a borda direita; reservando espaço a mais, o
  -- grupo parava ANTES dela — a engrenagem ficava a 54px da borda
  -- enquanto o play ficava a 13 da sua, e é essa diferença que se vê.
  --
  -- O erro anterior neste mesmo lugar foi o oposto (reservar de menos, e
  -- o último botão saía pela borda), o que explica a conta ter sido
  -- empurrada para cima sem recontar os botões.
  local nBotoes = (#faltando > 0) and 3 or 2
  local clusterW = nBotoes * M.botao + (nBotoes - 1) * M.espaco

  -- O QUE OS BLOCOS 1 A 3 OCUPARAM, contado item a item por quem
  -- desenhou. Daqui para a frente só vêm os botões do bloco 4, que são
  -- posicionados à parte e não entram nesta soma.
  encaixe.barraConteudo = encaixe.botoes * (M.botao + M.espaco)
                          + encaixe.extra
  encaixe.barraCluster = clusterW

  -- E O VÃO QUE SOBROU, quando dá para medir. Não manda em nada — a
  -- conta acima não depende dele. Fica no diagnóstico porque é a
  -- diferença entre "a conta fecha" e "a barra está repartida", e foi a
  -- segunda que faltou todas as vezes.
  do
    local xFim = xAtual()
    if xFim and encaixe.barraX0 and larguraJanela then
      encaixe.barraUsado = math.floor(xFim - encaixe.barraX0)
      encaixe.barraSobra = math.floor((larguraJanela - clusterW - M.margem)
                                      - (M.margem + encaixe.barraUsado))
    else
      encaixe.barraSobra, encaixe.barraUsado = nil, nil
    end
  end

  ImGui.SameLine(ctx, larguraJanela - clusterW - M.margem)

  -- ESCONDER/MOSTRAR CC LANES: pra sobrar mais espaço pro piano roll no
  -- editor MIDI do REAPER. Mexe no item MIDI que está aberto NO EDITOR
  -- MIDI no momento do clique — ver midi/cclanes.lua para o porquê de
  -- editar o state chunk em vez de usar uma ação nativa (não existe).
  -- FAIXAS DE PROGRAMAÇÃO: o editor MIDI que faltava para iluminação.
  if transportButton('faixas', faixas.abertas,
      (faixas.abertas and 'Fechar a Programação MIDI' or 'Programação MIDI')
      .. '\n\nMostra o que está gravado nesta música, uma linha por\n'
      .. 'controle, com o nome e a cor do .form — alinhado à forma\n'
      .. 'de onda logo acima.\n\n'
      .. 'Arraste as bordas de um bloco para ajustar; Del apaga.\n'
      .. 'Roda do mouse aproxima no tempo; Ctrl + roda muda a altura.') then
    faixas.abertas = not faixas.abertas
    faixas.at = 0
    faixas.sel = nil
    -- ABRE JÁ NO TAMANHO DO CONTEÚDO, até um limite.
    --
    -- Uma altura fixa não serve: cinco masters sozinhos ocupam 170px, e
    -- com 150 a faixa abria rolando antes de mostrar a primeira linha
    -- de botão. Quem abre quer VER, não rolar. O teto evita o contrário
    -- — uma música cheia tomando a janela inteira sem ser pedido.
    if faixas.abertas then faixas.ajustar = true end
    encaixe.w = 0   -- a área muda de tamanho: recalcula a escala
  end
  ImGui.SameLine(ctx)

  if #faltando > 0 then
    local linhas = {}
    for i, item in ipairs(faltando) do linhas[i] = '• ' .. item.texto end

    local comoResolver = {
      midi = 'Clique para abrir as configurações de MIDI, onde ficam o\n'
          .. 'atalho para as preferências de áudio do REAPER e o teste\n'
          .. 'de envio.\n\n'
          .. 'O REAPER só entrega o MIDI enquanto processa áudio. Parado,\n'
          .. 'a fila não é esvaziada e o Lumikit não recebe. Em\n'
          .. 'Audio > Playback, ligue "Run FX when stopped"; em\n'
          .. 'Audio > Device, desligue "Close audio device when stopped\n'
          .. 'and application is inactive".',
      arquivo = 'Clique para abrir as configurações de arquivo e carregar\n'
             .. 'a Tela Personalizada exportada do Lumikit Show.',
      gravacao = 'Clique para abrir as configurações de gravação e escolher\n'
              .. 'a track de destino.',
    }

    local destino = faltando[1].aba
    if transportButton('alerta', false,
        (#faltando == 1 and 'Falta resolver:' or 'Faltam resolver:') .. '\n'
        .. table.concat(linhas, '\n') .. '\n\n'
        .. (comoResolver[destino] or '')) then
      painel.aberto  = true
      abaAtual  = destino
      reaper.SetExtState(EXT_SECTION, 'painel.aberto', '1', true)
      reaper.SetExtState(EXT_SECTION, 'aba', abaAtual, true)
      encaixe.w = 0   -- a área muda de tamanho: recalcula a escala
    end
    ImGui.SameLine(ctx)
  end

  -- AVANÇADO abre todo o resto: ajustes, diagnóstico, calibração.
  --
  -- Desenhado por cima da própria janela (ver drawSettingsPanel), então
  -- não empurra o layout nem abre uma janela do sistema à parte.
  if transportButton('settings', painel.aberto,
      (painel.aberto and 'Fechar configurações' or 'Configurações')
      .. '\n\nAjustes: arquivo, porta MIDI, gravação, calibração\n'
      .. 'e o registro de diagnóstico.') then
    painel.aberto = not painel.aberto
    reaper.SetExtState(EXT_SECTION, 'painel.aberto', painel.aberto and '1' or '0', true)
    encaixe.w = 0   -- a área muda de tamanho: recalcula a escala
  end

  -- Os botões marcados esperando o play VIRARAM UM DISTINTIVO no canto
  -- do REC (ver o começo desta função). Aqui havia um texto solto, e
  -- desde que as Configurações passaram a ser alinhadas à direita ele
  -- era desenhado DEPOIS delas — ou seja, fora da janela. Na tela
  -- sobrava só o primeiro caractere: um "3" perdido no canto, sem
  -- explicação nenhuma.
end

--- Barra de abas do painel de configurações.
--
--  Uma aba por assunto, na ordem em que se usa: arquivo primeiro, como
--  é costume em qualquer software, e registro por último. A aba
--  escolhida é lembrada entre sessões.
--- Ícone de uma aba das Configurações, centrado em (cx, cy).
--
--  Só três primitivas: retângulo (contorno e cheio), círculo cheio e
--  linha. Nenhum triângulo fino, nenhuma malha — o tipo de forma que
--  NÃO sofre da armadilha de suavização documentada em
--  PROJECT_CONTEXT.md para os ícones da barra de transporte (aqueles
--  viraram imagem por causa de farpas em contornos vetorizados; estes
--  são simples o bastante pra não precisar disso).
local function desenharIconeAba(dl, chave, cx, cy, cor)
  if chave == 'arquivo' then
    ImGui.DrawList_AddRect(dl, cx - 4, cy - 6, cx + 4, cy + 6, cor, 1)
    ImGui.DrawList_AddLine(dl, cx - 2, cy - 2, cx + 2, cy - 2, cor, 1)
    ImGui.DrawList_AddLine(dl, cx - 2, cy + 1, cx + 2, cy + 1, cor, 1)
  elseif chave == 'geral' then
    -- Deslizadores: duas hastes com o cursor em alturas diferentes. É o
    -- desenho universal de "ajustes", e diz o que a aba tem — uma
    -- coleção de interruptores, e não uma função.
    ImGui.DrawList_AddLine(dl, cx - 3, cy - 6, cx - 3, cy + 6, cor, 1)
    ImGui.DrawList_AddLine(dl, cx + 3, cy - 6, cx + 3, cy + 6, cor, 1)
    ImGui.DrawList_AddRectFilled(dl, cx - 5.5, cy - 3, cx - 0.5, cy - 1, cor)
    ImGui.DrawList_AddRectFilled(dl, cx + 0.5, cy + 1, cx + 5.5, cy + 3, cor)
  elseif chave == 'midi' then
    ImGui.DrawList_AddCircleFilled(dl, cx - 4, cy, 1.7, cor)
    ImGui.DrawList_AddCircleFilled(dl, cx,     cy, 1.7, cor)
    ImGui.DrawList_AddCircleFilled(dl, cx + 4, cy, 1.7, cor)
  elseif chave == 'gravacao' then
    ImGui.DrawList_AddCircleFilled(dl, cx, cy, 5, cor)
  elseif chave == 'preparo' then
    -- Bandeira de largada: mastro e pano. É o que o preparo é — a marca
    -- do começo da música, escrita antes de qualquer gravação.
    ImGui.DrawList_AddLine(dl, cx - 4, cy - 6, cx - 4, cy + 6, cor, 1)
    ImGui.DrawList_AddRectFilled(dl, cx - 3, cy - 6, cx + 5, cy - 1, cor)
  elseif chave == 'atalhos' then
    ImGui.DrawList_AddRect(dl, cx - 6, cy - 4, cx + 6, cy + 4, cor, 1)
    ImGui.DrawList_AddRectFilled(dl, cx - 4, cy - 2, cx - 1, cy + 1, cor)
    ImGui.DrawList_AddRectFilled(dl, cx + 1, cy - 2, cx + 4, cy + 1, cor)
  elseif chave == 'grupos' then
    ImGui.DrawList_AddLine(dl, cx - 4, cy - 6, cx - 4, cy + 6, cor, 1)
    ImGui.DrawList_AddLine(dl, cx,     cy - 6, cx,     cy + 6, cor, 1)
    ImGui.DrawList_AddLine(dl, cx + 4, cy - 6, cx + 4, cy + 6, cor, 1)
    ImGui.DrawList_AddCircleFilled(dl, cx - 4, cy - 2, 1.8, cor)
    ImGui.DrawList_AddCircleFilled(dl, cx,     cy + 3, 1.8, cor)
    ImGui.DrawList_AddCircleFilled(dl, cx + 4, cy - 4, 1.8, cor)
  elseif chave == 'registro' then
    ImGui.DrawList_AddRect(dl, cx - 6, cy - 5, cx + 6, cy + 5, cor, 1)
    ImGui.DrawList_AddLine(dl, cx - 3, cy - 1, cx - 1, cy + 1, cor, 1)
    ImGui.DrawList_AddLine(dl, cx - 3, cy + 3, cx - 1, cy + 1, cor, 1)
  elseif chave == 'sobre' then
    -- Círculo com um "i": contorno mais um ponto e um traço. Sem fonte,
    -- sem glifo — as mesmas primitivas dos outros ícones.
    ImGui.DrawList_AddCircleFilled(dl, cx, cy, 6, cor)
    ImGui.DrawList_AddCircleFilled(dl, cx, cy - 2.5, 0.9, Theme.UI.bg)
    ImGui.DrawList_AddRectFilled(dl, cx - 0.9, cy - 0.5, cx + 0.9, cy + 3.5, Theme.UI.bg)
  end
end

--- Barra de abas das Configurações: faixa de destaque colorida na
--  lateral esquerda da aba ativa (em vez de um bloco de fundo sólido)
--  mais um ícone por aba — pedido explícito, no estilo de app de
--  configurações moderno. A linha inteira é clicável e destaca ao
--  passar o mouse, mesma técnica de ajusteToggle.
local function drawAbas()
  local ABAS = {
    { chave = 'arquivo',  titulo = 'Arquivo'  },
    -- GERAL: o que a janela FAZ, e não o que a música tem.
    --
    -- Isto estava tudo na aba Arquivo, sob "JANELA", junto do abrir e do
    -- recarregar da Tela Personalizada. Foram oito interruptores parar
    -- ali, e a aba passou a misturar duas perguntas diferentes: "qual
    -- tela estou usando" e "como o programa se comporta".
    { chave = 'geral',    titulo = 'Geral'    },
    { chave = 'midi',     titulo = 'MIDI'     },
    { chave = 'gravacao', titulo = 'Gravação' },
    { chave = 'preparo',  titulo = 'Preparo'  },
    { chave = 'atalhos',  titulo = 'Atalhos'  },
    { chave = 'grupos',   titulo = 'Grupos'   },
    { chave = 'registro', titulo = 'Registro' },
    { chave = 'sobre',    titulo = 'Sobre'    },
  }

  local ALTURA = 32
  local dl = ImGui.GetWindowDrawList(ctx)

  for _, aba in ipairs(ABAS) do
    local largura = ImGui.GetContentRegionAvail(ctx)
    local x0, y0 = ImGui.GetCursorScreenPos(ctx)
    x0, y0 = math.floor(x0), math.floor(y0)

    ImGui.InvisibleButton(ctx, '##aba_' .. aba.chave, largura, ALTURA)
    local hovered = ImGui.IsItemHovered(ctx)
    local clicked = ImGui.IsItemClicked(ctx)
    if clicked then
      abaAtual = aba.chave
      reaper.SetExtState(EXT_SECTION, 'aba', abaAtual, true)
    end
    local ativa = (abaAtual == aba.chave)

    if ativa then
      ImGui.DrawList_AddRectFilled(dl, x0, y0, x0 + largura, y0 + ALTURA, Theme.UI.panel)
      ImGui.DrawList_AddRectFilled(dl, x0, y0, x0 + 3, y0 + ALTURA, Theme.UI.accent)
    elseif hovered then
      ImGui.DrawList_AddRectFilled(dl, x0, y0, x0 + largura, y0 + ALTURA, Theme.UI.panelHover)
    end

    local cor = ativa and Theme.UI.text or Theme.UI.textDim
    desenharIconeAba(dl, aba.chave, x0 + 17, y0 + ALTURA * 0.5, cor)

    ImGui.SetCursorScreenPos(ctx, x0 + 32, y0 + 8)
    ImGui.TextColored(ctx, cor, aba.titulo)

    ImGui.SetCursorScreenPos(ctx, x0, y0 + ALTURA)
  end
end

--- Rótulo de grupo dentro de uma aba.
local function grupo(texto)
  ImGui.TextColored(ctx, 0x5F6672FF, texto)

  -- Traço fino embaixo do rótulo — separa os grupos de ajustes sem
  -- precisar de um Separator() inteiro, que tem folga maior que o
  -- visual pedido. Uma linha simples via DrawList, arredondada a
  -- pixel inteiro pra não ficar mais grossa que 1px de verdade.
  local x0, y0 = ImGui.GetCursorScreenPos(ctx)
  x0, y0 = math.floor(x0), math.floor(y0)
  local largura = math.floor(ImGui.GetContentRegionAvail(ctx))
  local dl = ImGui.GetWindowDrawList(ctx)
  ImGui.DrawList_AddLine(dl, x0, y0 + 1, x0 + largura, y0 + 1, 0x20232AFF, 1)

  ImGui.Dummy(ctx, 1, 6)
end

--- Conteúdo da aba escolhida, dentro da janela de configurações.
local function drawAbaAtual()

  if abaAtual == 'arquivo' then
    grupo('LAYOUT')
    if ImGui.Button(ctx, 'Abrir tela', 90, 0) then browseForm() end
    dica('Carrega a Tela Personalizada: o arquivo .form exportado\n'
      .. 'do Lumikit Show.\n'
      .. 'Tudo vem dele: botões, cores, grupos, ícones e MIDI.')

    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Recarregar', 92, 0) then
      if layout and layout.source then loadForm(layout.source) end
    end
    dica('Relê o mesmo arquivo, depois de exportar um novo do Lumikit.')

    if layout then
      ImGui.TextColored(ctx, 0x777F8CFF, statusText)
    end

    ImGui.Dummy(ctx, 1, 6)
    grupo('FORMA DE ONDA')

    -- Track de REFERÊNCIA, escolhida pelo usuário.
    --
    -- Estava fixa em "VS" no código, o que só servia para quem usasse
    -- esse nome. Agora é a lista das tracks do projeto.
    --
    -- O nome era "Track da música", e isso fazia pensar que era ali que
    -- se escolhia a música — logo abaixo de "TELA PERSONALIZADA", numa
    -- aba onde tudo o mais é sobre qual arquivo abrir. O que se aponta
    -- aqui é de onde SAI O DESENHO DA ONDA, e o melhor candidato é a
    -- track com a guia: é ela que deixa a batida visível enquanto se
    -- programa.
    ajuste('Track de referência', 'para gerar a onda', 230)
    ImGui.SetNextItemWidth(ctx, 230)
    local ondaRotulo = (waveTrack ~= '' and waveTrack) or 'automática'
    if ImGui.BeginCombo(ctx, '##trackonda', ondaRotulo) then
      if ImGui.Selectable(ctx, 'automática', waveTrack == '') then
        waveTrack = ''
        Waveform.setTrack('', nil)
        Waveform.reset()
        reaper.SetExtState(EXT_SECTION, 'wave_track', '', true)
      end
      for _, t in ipairs(tracks) do
        if ImGui.Selectable(ctx, t.name, t.name == waveTrack) then
          waveTrack = t.name
          Waveform.setTrack(t.name, t.index)
          Waveform.reset()
          reaper.SetExtState(EXT_SECTION, 'wave_track', waveTrack, true)
        end
      end
      ImGui.EndCombo(ctx)
    end
    dica('De qual track sai a forma de onda desenhada na timeline.\n\n'
      .. 'Recomendável apontar a track que contém a GUIA da música —\n'
      .. 'é a referência que deixa a batida à vista enquanto você\n'
      .. 'programa a luz.\n\n'
      .. 'Em "automática", usa a primeira track com áudio no trecho.')

    ImGui.Dummy(ctx, 1, 6)
  elseif abaAtual == 'geral' then
    -- QUATRO GRUPOS, e não uma lista de dez sob "JANELA".
    --
    -- Era um título só, e só três dos dez interruptores eram da janela.
    -- Os outros mexiam na barra de transporte, na Programação MIDI e no
    -- teclado — e procurar "onde eu desligo o ímã" numa lista de dez
    -- itens sem divisão é ler os dez.
    --
    -- A ordem é a de quem procura: primeiro a janela em volta, depois a
    -- barra, depois a área de trabalho, e por último o teclado, que é um
    -- só. Nenhum mudou de nome nem de comportamento.
    grupo('JANELA')

    local chTop, top = ajusteToggle('Sempre visível',
      'mantém a janela acima do REAPER.', chrome.aoAlto,
      'Mantém a janela acima do REAPER, para não precisar alternar.')
    if chTop then chrome.aoAlto = top end

    local chDet, det = ajusteToggle('Detalhes',
      'geometria e comando MIDI do controle sob o cursor.', opcoes.detalhes,
      'Mostra tag, tamanho, comando MIDI e grupos do controle\n'
      .. 'sob o cursor.')
    if chDet then opcoes.detalhes = det end

    local chDica, dc = ajusteToggle('Dicas',
      'balões de ajuda ao passar o mouse.', opcoes.dicas,
      'Desligue quando já souber a interface: a dica da lista de\n'
      .. 'faixas cobre boa parte da área de programação enquanto\n'
      .. 'se trabalha nela.')
    if chDica then
      opcoes.dicas = dc
      reaper.SetExtState(EXT_SECTION, 'dicas', dc and '1' or '0', true)
    end

    ImGui.Dummy(ctx, 1, 10)
    grupo('BARRA DE TRANSPORTE')

    local chReg, rg = ajusteToggle('Botões de música',
      'anterior e próxima, na barra de transporte.', opcoes.regioes,
      'Mostra os botões de música anterior e próxima.')
    if chReg then
      opcoes.regioes = rg
      reaper.SetExtState(EXT_SECTION, 'op_regioes', rg and '1' or '0', true)
    end

    local chRel, rl = ajusteToggle('Relógio',
      'a posição em minutos e segundos, na barra.', opcoes.relogio,
      'O REAPER já mostra a posição, maior e sempre à vista.')
    if chRel then
      opcoes.relogio = rl
      reaper.SetExtState(EXT_SECTION, 'op_relogio', rl and '1' or '0', true)
    end

    local chRep, rp = ajusteToggle('Repetir a música',
      'ao saltar para uma música, repetir só ela.', opcoes.repetir,
      'Programar é repetir o mesmo trecho; por isso vem ligado.')
    if chRep then
      opcoes.repetir = rp
      reaper.SetExtState(EXT_SECTION, 'op_repetir', rp and '1' or '0', true)
    end

    ImGui.Dummy(ctx, 1, 10)
    grupo('PROGRAMAÇÃO MIDI')

    local chVira, vp = ajusteToggle('Virar a página',
      'com zoom, a vista acompanha a reprodução.', faixas.seguirCursor,
      'O cursor vai até a borda e a vista salta, como no REAPER.')
    if chVira then
      faixas.seguirCursor = vp
      reaper.SetExtState(EXT_SECTION, 'seguir_cursor',
                         vp and '1' or '0', true)
    end

    local chIma, im = ajusteToggle('Ímã',
      'a borda arrastada cola na nota mais próxima.', opcoes.ima,
      'Dois controles clicados quase juntos ficam a milissegundos um do\n'
      .. 'outro. Com o ímã, arrastar um para perto do outro já casa os dois.')
    if chIma then
      opcoes.ima = im
      reaper.SetExtState(EXT_SECTION, 'op_ima', im and '1' or '0', true)
    end

    local chZm, zm = ajusteToggle('Zoom no ponteiro',
      'aproximar em torno do mouse, e não do cursor.', opcoes.zoomNoMouse,
      'Apagado: aproxima em torno do cursor de reprodução, mantendo\n'
      .. 'debaixo do olho o ponto que está tocando.\n'
      .. 'Aceso: aproxima em torno do ponteiro, como num editor de áudio.')
    if chZm then
      opcoes.zoomNoMouse = zm
      reaper.SetExtState(EXT_SECTION, 'op_zoom_mouse', zm and '1' or '0', true)
    end

    ImGui.Dummy(ctx, 1, 10)
    grupo('TECLADO')

    local chSc, sc = ajusteToggle('Atalhos',
      'ativa as teclas da tela e as F1-F12.', opcoes.atalhos,
      'Ativa as teclas da Tela Personalizada (A-Z, 0-9, Espaço)\n'
      .. 'e as F1-F12\n'
      .. 'definidas na aba Atalhos.')
    if chSc then opcoes.atalhos = sc end

  elseif abaAtual == 'midi' then
    grupo('MOTOR DE ÁUDIO')

    -- SEMPRE VISÍVEL, não só quando a detecção acusa.
    --
    -- O REAPER não entrega MIDI por conta própria: o StuffMIDIMessage
    -- enfileira, e quem esvazia a fila é a thread de áudio. Parado, com
    -- as preferências erradas, ela não roda — e o Lumikit não recebe
    -- nada, embora o envio tenha "funcionado" do lado do script.
    local rodando = MidiOut.audioRunning()
    ImGui.TextColored(ctx, rodando and 0x88CC88FF or 0xFF8844FF,
      rodando and '● processando — o MIDI é entregue'
              or '● PARADO — o MIDI fica na fila e não chega ao Lumikit')

    ajuste('Preferências de áudio', 'precisam permitir MIDI com o transporte parado.', 178)
    if ImGui.Button(ctx, 'Abrir preferências', 178, 0) then
      reaper.Main_OnCommand(40016, 0)
    end
    dica('Duas opções precisam estar assim para o MIDI sair com o\n'
      .. 'transporte parado:\n\n'
      .. 'Audio > Playback: LIGAR "Run FX when stopped"\n'
      .. 'Audio > Device: DESLIGAR "Close audio device when stopped\n'
      .. 'and application is inactive"')

    ajuste('Testar rota', 'caminho mais curto, sem a tela nem as regras.', 110)
    if ImGui.Button(ctx, 'Testar agora', 110, 0) then
      local ok = MidiOut.sendTestNote()
      log(('teste manual: %s  (motor de áudio %s)')
        :format(ok and 'enviado' or 'falhou',
                rodando and 'rodando' or 'PARADO'))
    end
    dica('Manda uma nota pelo caminho mais curto, sem passar pelo\n'
      .. '.form nem pelas regras. Se ela não chegar ao Lumikit com o\n'
      .. 'transporte parado, o problema está entre o REAPER e a porta.')

    ImGui.Dummy(ctx, 1, 6)
    grupo('CAMINHO DO ENVIO')

    -- DOIS CAMINHOS ATÉ O LUMIKIT.
    --
    -- "Porta direta" fala com a porta MIDI sem passar por track. É o
    -- mais simples, mas depende de a thread de áudio do REAPER esvaziar
    -- uma fila — e com o transporte parado, conforme as preferências,
    -- ela pode não rodar. As mensagens somem sem erro nenhum.
    --
    -- "Pela track" entra no REAPER como se viesse de um teclado MIDI e
    -- sai pela saída de hardware da track armada. É o MESMO percurso
    -- que funciona quando o REAPER toca o item gravado.
    local porTrack = (MidiOut.route == 'track')

    if ImGui.RadioButton then
      if ImGui.RadioButton(ctx, 'Porta direta', not porTrack) then
        MidiOut.route = 'porta'
        reaper.SetExtState(EXT_SECTION, 'route', 'porta', true)
      end
      ImGui.SameLine(ctx)
      if ImGui.RadioButton(ctx, 'Pela track (recomendado)', porTrack) then
        MidiOut.route = 'track'
        reaper.SetExtState(EXT_SECTION, 'route', 'track', true)
        -- Deixa a track pronta na hora: armar, entrada e monitoração.
        local pronta, falta = Timeline.armForVirtualKeyboard()
        rotaAviso = pronta and 'Track preparada: armada, entrada de teclado e monitoração ligadas.'
          or ('Track preparada, mas ' .. tostring(falta) .. '.')
        log('rota pela track: ' .. rotaAviso)
      end
    else
      local chR, r2 = ImGui.Checkbox(ctx, 'Enviar pela track', porTrack)
      if chR then
        MidiOut.route = r2 and 'track' or 'porta'
        reaper.SetExtState(EXT_SECTION, 'route', MidiOut.route, true)
      end
    end

    if porTrack then
      local pronta, falta, devSaida = Timeline.armForVirtualKeyboard()

      -- Estado completo da track, para conferir sem abrir o REAPER.
      ImGui.TextColored(ctx, 0x777F8CFF,
        ('Entrada da track: %s'):format(Timeline.describeInput()))

      -- Mostra PARA ONDE a track está mandando, com nome.
      if pronta and devSaida then
        local nome = ('dispositivo %d'):format(devSaida)
        for _, d in ipairs(devices) do
          if d.index == devSaida then nome = d.name end
        end
        ImGui.TextColored(ctx, 0x88CC88FF,
          ('Saída da track: %s'):format(nome))
      else
        ImGui.TextColored(ctx, 0xFF8844FF, tostring(falta))
      end

      -- Apontar a saída para a porta escolhida acima.
      --
      -- Num botão separado porque é a decisão mais consequente de
      -- todas: mandar para a porta errada no meio de um show manda os
      -- comandos para o lugar errado.
      if MidiOut.deviceIndex then
        if ImGui.Button(ctx, ('Apontar a saída para %s')
             :format(MidiOut.deviceName or 'a porta escolhida')) then
          Timeline.setMidiHardwareOut(MidiOut.deviceIndex, 0)
          Timeline.armForVirtualKeyboard()
          rotaAviso = ('Saída da track apontada para %s.')
            :format(MidiOut.deviceName)
          log(rotaAviso)
        end
        dica('Configura a saída de hardware MIDI da track para a porta\n'
          .. 'escolhida em PORTA DE SAÍDA, em todos os canais.')
      end

      if rotaAviso then
        ImGui.SameLine(ctx)
        ImGui.TextColored(ctx, 0x88CC88FF, rotaAviso)
      end
    else
      ImGui.TextColored(ctx, 0x777F8CFF,
        'Se os comandos não chegam com o transporte parado, experimente '
        .. '"Pela track".')
    end

    ImGui.Dummy(ctx, 1, 6)
    grupo('ENVIO')
    local chSend, snd = ajusteToggle('Enviar MIDI ao Lumikit',
      'desligado, os cliques só marcam o estado na tela.', MidiOut.enabled)
    if chSend then MidiOut.enabled = snd end

    ImGui.Dummy(ctx, 1, 6)
    grupo('PORTA DE SAÍDA')
    drawMidiBar()

    ImGui.Dummy(ctx, 1, 6)
    grupo('COMPENSAÇÃO DE ATRASO')

    -- O botão "Usar Nms" só aparece quando há uma sugestão pendente da
    -- calibração automática — a largura reservada pro controle muda de
    -- quadro a quadro conforme ele existe ou não.
    local auto = (Timeline.outputLatency() + Timeline.frameCompensation) * 1000
    local sugestaoMs, temSugestao
    if autoCal and Calibration.ready(autoCal) then
      local m = Calibration.result(autoCal)
      if m and math.abs(m - latency) > 0.015 then
        sugestaoMs = m
        temSugestao = true
      end
    end

    ajuste(('Atraso (+%.0f ms automático)'):format(auto), nil,
      temSugestao and 300 or 200)
    ImGui.SetNextItemWidth(ctx, 200)
    local chOff, ms = ImGui.SliderDouble(ctx, '##atraso', latency * 1000, -100, 500, '%.0f ms')
    dica('Compensa o seu tempo de reação: o clique acontece depois de\n'
      .. 'você ouvir a batida.')
    if chOff then
      latency = ms / 1000
      reaper.SetExtState(EXT_SECTION, EXT_OFFSET, tostring(latency), true)
    end

    if temSugestao then
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, ('Usar %d ms'):format(math.floor(sugestaoMs * 1000 + 0.5))) then
        latency = sugestaoMs
        reaper.SetExtState(EXT_SECTION, EXT_OFFSET, tostring(latency), true)
        autoCal = nil
      end
    end

  elseif abaAtual == 'gravacao' then
    grupo('DESTINO')
    drawRecordBar()

    ImGui.Dummy(ctx, 1, 6)
    grupo('FADERS')
    ajuste('Roda do mouse', 'passo por clique; com Shift, sempre o passo fino.', 220)
    ImGui.SetNextItemWidth(ctx, 220)
    local chW, pct = ImGui.SliderDouble(ctx, '##rodaDoMouse',
      Session.WHEEL_STEP * 100, 1, 50, '%.0f%% por clique')
    dica('Quanto o fader anda a cada clique da roda.\n'
      .. 'Maior chega mais rápido ao extremo; menor dá mais controle.\n'
      .. 'Com Shift o passo é sempre pequeno, para o acerto fino.')
    if chW then
      Session.WHEEL_STEP = pct / 100
      reaper.SetExtState(EXT_SECTION, 'wheel_step',
                         tostring(Session.WHEEL_STEP), true)
    end

    ImGui.Dummy(ctx, 1, 6)
    grupo('COMPORTAMENTO')
    local chF, fp = ajusteToggle('Seguir play',
      'acende os botões conforme a gravação passa pelo cursor.', espelho.seguir)
    if chF then espelho.seguir = fp end

    -- DIZ QUANDO DESLIGAR, e mostra que já está desligado sozinho.
    --
    -- Ligado com a track entregando na mesma porta, cada nota chegava
    -- duas vezes ao Lumikit e o botão — que é toggle — voltava ao
    -- estado anterior. O programa se cala sozinho quando detecta isso,
    -- mas só detecta a saída de hardware da track: quem entrega por
    -- outro caminho precisa desligar aqui.
    local chM, ms2 = ajusteToggle('Espelho envia MIDI',
      espelho.duplicaria()
        and 'a track já entrega nesta porta — em silêncio na reprodução.'
        or 'na reprodução, manda ao Lumikit o que está gravado.\n'
           .. 'Desligue se o Lumikit já recebe pela track.',
      espelho.envia)
    if chM then espelho.envia = ms2 end

  elseif abaAtual == 'preparo' then
    -- O QUE O LUMIBRIDGE ESCREVE SOZINHO AO COMEÇAR UMA MÚSICA.
    --
    -- Tudo o que está aqui já acontecia, mas fixo no código. Cada
    -- operador abre a música do seu jeito: um quer o release, outro já
    -- apaga tudo pela mesa antes de começar; um quer os faders no
    -- máximo, outro sobe a luz na mão. Escrever por conta própria o que
    -- o outro não pediu é o mesmo que estragar o trabalho dele.
    grupo('AUTOMÁTICO')
    local chPA, pa = ajusteToggle('Preparar sozinho',
      'ao gravar numa música ainda vazia, escreve a abertura sem pedir.',
      preparo.auto,
      'Ligado: apertar REC numa música vazia cria o item, o release e\n'
      .. 'os pontos de fader, tudo de uma vez.\n\n'
      .. 'Desligado: o REC só cria o item onde gravar. Nada mais é\n'
      .. 'escrito sem você pedir.')
    if chPA then
      preparo.auto = pa
      reaper.SetExtState(EXT_SECTION, 'prep_auto', pa and '1' or '0', true)
    end
    ImGui.TextColored(ctx, 0x6B7280FF,
      'O botão "Preparar" da barra continua funcionando com isto desligado.')

    ImGui.Dummy(ctx, 1, 8)
    grupo('RELEASE ALL')
    local chPR, pr = ajusteToggle('Release no primeiro tempo',
      'apaga o que sobrou da música anterior antes desta abrir.',
      preparo.release,
      'Uma nota no primeiro quadradinho da música, antes de tudo.\n\n'
      .. 'Sem ela, o que ficou aceso no Lumikit da música anterior\n'
      .. 'soma-se à abertura desta.')
    if chPR then
      preparo.release = pr
      reaper.SetExtState(EXT_SECTION, 'prep_release', pr and '1' or '0', true)
    end

    -- QUAL controle é o release desta tela.
    --
    -- A descoberta por nome ('RELEASE ALL', 'BACKOUT'...) acerta na
    -- maioria dos .form e erra em silêncio nos outros — e "erra em
    -- silêncio" aqui significa música abrindo com a luz da anterior por
    -- cima. Poder apontar o controle certo é o que torna isto utilizável
    -- em qualquer tela, e não só nas que seguem a nomenclatura.
    local escolhido = session and Session.findRelease(session) or nil
    ajuste('Controle do release', 'qual botão desta tela apaga tudo.', 240)
    ImGui.SetNextItemWidth(ctx, 240)
    local previa = 'nenhum controle com MIDI'
    if escolhido then
      previa = escolhido.text or ('controle #' .. tostring(escolhido.tag))
      if not (session and session.releaseTag) then
        previa = previa .. '  (pelo nome)'
      end
    end
    if ImGui.BeginCombo(ctx, '##releaseTag', previa) then
      if ImGui.Selectable(ctx, 'Descobrir pelo nome',
                          not (session and session.releaseTag)) then
        saveReleaseTag(nil)
      end
      -- Só controles com nota MIDI: um release sem mensagem não apaga
      -- nada, e oferecê-lo seria oferecer uma escolha que não funciona.
      local lista = {}
      for tag, e in pairs(session and session.byTag or {}) do
        if not (session.faderTags and session.faderTags[tag]) then
          for _, cmd in ipairs(e.commands or {}) do
            if (cmd.status & 0xF0) == 0x90 then
              lista[#lista + 1] = { tag = tag, texto = e.text or ('#' .. tostring(tag)),
                                    nota = cmd.data1 }
              break
            end
          end
        end
      end
      table.sort(lista, function(a, b) return a.texto:upper() < b.texto:upper() end)
      for _, item in ipairs(lista) do
        if ImGui.Selectable(ctx, ('%s   ·   nota %d'):format(item.texto, item.nota),
                            session.releaseTag == item.tag) then
          saveReleaseTag(item.tag)
        end
      end
      ImGui.EndCombo(ctx)
    end
    dica('A escolha vale só para esta Tela Personalizada, e é lembrada\npor arquivo.\n'
      .. 'Serve também para o botão Release da barra de transporte.')

    ImGui.Dummy(ctx, 1, 8)
    grupo('FADERS')
    local chPF, pf = ajusteToggle('Pontos no começo e no fim',
      'segura o valor do fader do início ao fim da música.',
      preparo.faders,
      'Dois pontos de automação por fader da tela: um na primeira\n'
      .. 'batida e outro na última.\n\n'
      .. 'Sem o ponto do fim, o valor do último gesto vale até o fim\n'
      .. 'do projeto — inclusive por cima da música seguinte.')
    if chPF then
      preparo.faders = pf
      reaper.SetExtState(EXT_SECTION, 'prep_faders', pf and '1' or '0', true)
    end

    local chPC, pc = ajusteToggle('Ignorar a tela e usar 100%',
      'por padrão a música abre com os faders como estão na tela.',
      preparo.cem,
      'DESLIGADO (padrão): a música abre com cada fader na posição em\n'
      .. 'que ele está na tela. Deixe o GERAL em zero antes de preparar\n'
      .. 'e a música nasce escura, para subir a luz gravando.\n\n'
      .. 'Ligado: a posição da tela é ignorada e todos abrem no máximo.')
    if chPC then
      preparo.cem = pc
      reaper.SetExtState(EXT_SECTION, 'prep_fader_cem', pc and '1' or '0', true)
    end

  elseif abaAtual == 'atalhos' then
    if not shortcuts.built and layout then buildShortcuts() end

    local formList = {}
    for _, sc in ipairs(shortcuts) do
      if sc.source ~= 'lumibridge' then formList[#formList + 1] = sc end
    end

    grupo(('DO ARQUIVO .FORM  ·  %d tecla(s)'):format(#formList))
    ImGui.TextColored(ctx, 0x6B7280FF,
      'Definidos no Lumikit, não aqui. Para mudar, edite a Tela Personalizada e clique em "Recarregar".')
    ImGui.Dummy(ctx, 1, 4)

    if #formList == 0 then
      ImGui.TextColored(ctx, 0x6B7280FF, '(nenhum atalho nesta tela)')
    else
      table.sort(formList, function(a, b)
        return (Compat.keyName(a.code) or '') < (Compat.keyName(b.code) or '')
      end)
      for _, sc in ipairs(formList) do
        linhaAtalho('form' .. tostring(sc.code),
          Compat.keyName(sc.code) or '?',
          sc.element.text ~= '' and sc.element.text or '(sem nome)',
          sc.covered and 'oculto' or nil,
          false)
      end
    end

    ImGui.Dummy(ctx, 1, 12)

    local usadas = 0
    for _, code in ipairs(FKeys.CODES) do
      local tag = fkeyMap[code]
      if tag and session and session.byTag[tag] then usadas = usadas + 1 end
    end

    grupo(('F1 A F12  ·  %d de %d usadas'):format(usadas, #FKeys.CODES))
    ImGui.TextColored(ctx, 0x6B7280FF,
      'Clique com o botão DIREITO num controle da tela pra atribuir.')
    ImGui.Dummy(ctx, 1, 4)

    for _, code in ipairs(FKeys.CODES) do
      local tag = fkeyMap[code]
      local el  = tag and session and session.byTag[tag]
      local nome = el and (el.text ~= '' and el.text or '(sem nome)') or nil
      if linhaAtalho('fkey' .. tostring(code), FKeys.label(code), nome, nil, el ~= nil) then
        fkeyMap[code] = nil
        saveFKeys()
        shortcuts = {}
      end
    end

  elseif abaAtual == 'grupos' then
    -- Duas linhas, não três: o cartão é largo o bastante pra caber mais
    -- texto por linha, e três linhas curtas desperdiçavam a horizontal.
    ImGui.TextColored(ctx, 0x6B7280FF,
      'Segure a tecla do grupo (1 a 9, depois 0) e gire a roda do mouse em qualquer lugar da tela:\n'
      .. 'os faders marcados abaixo se movem juntos, mesmo sem o mouse estar em cima de nenhum deles.')
    ImGui.Dummy(ctx, 1, 10)

    local faders = {}
    if layout then
      for _, el in ipairs(layout.elements) do
        if el.kind == Model.KIND.FADER and el.tag then
          faders[#faders + 1] = el
        end
      end
      table.sort(faders, function(a, b) return (a.tag or 0) < (b.tag or 0) end)
    end

    if #faders == 0 then
      ImGui.TextColored(ctx, 0x6B7280FF, '(esta tela não tem faders)')
    else
      -- TIRA DE SELEÇÃO DO GRUPO: 10 números, o escolhido com fundo
      -- azul. Antes os dez grupos apareciam todos empilhados, um
      -- embaixo do outro — virava uma rolagem longa. Posições
      -- ABSOLUTAS (não SameLine em fileira): mesma técnica já usada na
      -- moldura e nos ícones das abas, sem depender de como o ImGui
      -- rastreia "o último item" entre chamadas de desenho manual.
      --
      -- O ESTADO DE CADA GRUPO É O CONTORNO do quadradinho (escolhido
      -- entre quatro alternativas desenhadas): borda azul = configurado
      -- e ativo, borda cinza = tem faders mas está pausado, sem borda =
      -- vazio. Antes era um ponto/quadradinho dentro do chip, que
      -- poluía sem comunicar melhor.
      local rowX, rowY = ImGui.GetCursorScreenPos(ctx)
      rowX, rowY = math.floor(rowX), math.floor(rowY)
      local CHIP, GAP = 32, 6
      local dl = ImGui.GetWindowDrawList(ctx)

      for i, num in ipairs(FaderGroups.NUMBERS) do
        local x0 = rowX + (i - 1) * (CHIP + GAP)
        ImGui.SetCursorScreenPos(ctx, x0, rowY)
        ImGui.InvisibleButton(ctx, '##gnum_' .. num, CHIP, CHIP)
        if ImGui.IsItemClicked(ctx) then grupoSelecionado = num end

        local selecionado = (grupoSelecionado == num)
        local gExiste = faderGroups[num]
        local temFaders = gExiste and gExiste.tags and #gExiste.tags > 0
        local estaAtivo = temFaders and gExiste.ativo ~= false

        ImGui.DrawList_AddRectFilled(dl, x0, rowY, x0 + CHIP, rowY + CHIP,
          selecionado and Theme.UI.accent or Theme.UI.panel, 7)

        -- Contorno só nos grupos configurados, e nunca no selecionado:
        -- ali o fundo azul cheio já diz tudo, e uma borda por cima
        -- viraria ruído.
        if temFaders and not selecionado then
          ImGui.DrawList_AddRect(dl, x0, rowY, x0 + CHIP, rowY + CHIP,
            estaAtivo and Theme.UI.accent or 0x454B57FF, 7, 0, 1.5)
        end

        local corTxt = selecionado and 0x04294FFF
          or (temFaders and Theme.UI.text or Theme.UI.textDim)
        local wNum, hNum = ImGui.CalcTextSize(ctx, num)
        ImGui.SetCursorScreenPos(ctx,
          math.floor(x0 + (CHIP - wNum) * 0.5),
          math.floor(rowY + (CHIP - hNum) * 0.5))
        ImGui.TextColored(ctx, corTxt, num)
      end

      ImGui.SetCursorScreenPos(ctx, rowX, rowY + CHIP)
      ImGui.Dummy(ctx, 1, 12)

      -- PAINEL DO GRUPO ESCOLHIDO — só um por vez, não os dez juntos.
      local num = grupoSelecionado
      ImGui.PushID(ctx, 'fgrupo' .. num)
      local g = faderGroups[num] or FaderGroups.empty()

      grupo('GRUPO ' .. num)

      local chAtivo, novoAtivo = ajusteToggle('Ativo',
        'desliga o grupo inteiro sem apagar os faders escolhidos.',
        g.ativo ~= false)
      if chAtivo then
        g.ativo = novoAtivo
        faderGroups[num] = g
        saveFaderGroups()
      end

      local mudouModo, ehMesmo = segmento2('Modo', 'Diferença', 'Mesmo valor',
        g.mode == FaderGroups.MODE_SAME)
      if mudouModo then
        g.mode = ehMesmo and FaderGroups.MODE_SAME or FaderGroups.MODE_DIFF
        faderGroups[num] = g
        saveFaderGroups()
      end

      ImGui.Dummy(ctx, 1, 10)

      -- Busca e ações em massa só aparecem quando a lista compensa —
      -- num .form com poucos faders isso seria só ruído.
      if #faders > 8 then
        ImGui.SetNextItemWidth(ctx, 220)
        local chBusca, txtBusca = ImGui.InputText(ctx, '##buscaFader', buscaFader)
        if ImGui.IsItemActive(ctx) then campoTextoAtivo = true end
        if chBusca then buscaFader = txtBusca end
        dica('Filtra a lista pelo nome do fader.')

        ImGui.SameLine(ctx)
        if ImGui.SmallButton(ctx, 'marcar todos') then
          g.tags = {}
          for _, el in ipairs(faders) do table.insert(g.tags, el.tag) end
          faderGroups[num] = g
          saveFaderGroups()
        end

        ImGui.SameLine(ctx)
        if ImGui.SmallButton(ctx, 'limpar') then
          g.tags = {}
          faderGroups[num] = g
          saveFaderGroups()
        end

        ImGui.Dummy(ctx, 1, 6)
      end

      local filtro = buscaFader:upper()
      for _, el in ipairs(faders) do
        local rotulo = el.text ~= '' and el.text or ('fader ' .. tostring(el.tag))
        if filtro == '' or rotulo:upper():find(filtro, 1, true) then
          local marcado = false
          for _, t in ipairs(g.tags) do
            if t == el.tag then marcado = true end
          end

          local mudouTag, novoMarcado = itemMarcavel(el.tag, rotulo, marcado)
          if mudouTag then
            if novoMarcado then
              table.insert(g.tags, el.tag)
            else
              for i2 = #g.tags, 1, -1 do
                if g.tags[i2] == el.tag then table.remove(g.tags, i2) end
              end
            end
            faderGroups[num] = g
            saveFaderGroups()
          end
        end
      end

      ImGui.PopID(ctx)
    end

  elseif abaAtual == 'registro' then
    grupo('DETALHADO')
    local chV, vb = ajusteToggle('Detalhado',
      'anota cada ação no console; envie isto quando algo der errado.', painel.verbose,
      'Anota cada ação: comandos enviados, aberturas, cortes e\n'
      .. 'notas escritas. É o que enviar quando algo dá errado.')
    if chV then
      -- NÃO persiste entre sessões, de propósito: Detalhado sempre
      -- começa desligado quando o script abre, senão uma sessão fica
      -- gerando log sem necessidade só porque a anterior tinha deixado
      -- ligado.
      painel.verbose = vb
      if painel.verbose then log('registro ligado') else painel.linhas = {} end
    end

    if painel.verbose then
      -- Linha própria, NÃO grudada na linha do checkbox acima: o
      -- checkbox agora fica alinhado à direita (ver ajuste()), então
      -- continuar com SameLine aqui empurrava os quatro botões pra
      -- fora da área visível do cartão — sumiam sem erro nenhum.
      ImGui.Dummy(ctx, 1, 10)
      grupo('AÇÕES')

      if ImGui.Button(ctx, 'Copiar', 90, 0) then
        logAviso = copyToClipboard(logText())
          and 'Registro copiado. Cole onde precisar.'
          or 'Não foi possível copiar. Use Salvar.'
      end
      dica('Copia o registro inteiro, com o cabeçalho do ambiente.')

      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, 'Salvar', 90, 0) then
        local caminho, err = saveLog()
        logAviso = caminho and ('Salvo em: ' .. caminho)
          or ('Não foi possível salvar: ' .. tostring(err))
      end
      dica('Grava um arquivo de texto com data e hora no nome.')

      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, 'Abrir pasta', 100, 0) then
        local pasta, semSWS = openLogFolder()
        logAviso = semSWS
          and ('Pasta: ' .. pasta .. '  (instale a extensão SWS para abrir daqui)')
          or ('Pasta aberta: ' .. pasta)
      end
      dica('Abre a pasta onde os registros ficam guardados.')

      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, 'Limpar', 90, 0) then
        painel.linhas = {}
        logAviso = nil
      end
      dica('Apaga o registro desta sessão. Não afeta arquivos já salvos.')

      ImGui.Dummy(ctx, 1, 4)
      ImGui.TextColored(ctx, 0x777F8CFF, ('%d linha(s)'):format(#painel.linhas))
      if logAviso then
        ImGui.SameLine(ctx)
        ImGui.TextColored(ctx, 0x88CC88FF, '·  ' .. logAviso)
      end

      ImGui.Dummy(ctx, 1, 6)
      grupo('MENSAGENS')

      -- Campo do log num tom diferente do resto do cartão (mais escuro,
      -- de "console"), com a MESMA borda fina do cartão em volta — a
      -- mesma técnica de child preenchido (ver drawSettingsPanel):
      -- desenha uma faixa na cor da borda do tamanho cheio, depois o
      -- campo de verdade por cima, encolhido 1px em cada lado.
      -- math.floor nas quatro medidas: coordenada fracionária faz a
      -- borda horizontal (linha comprida, uma só linha de pixels) e a
      -- vertical (mesma coisa, no outro eixo) caírem em posições de
      -- sub-pixel diferentes, e a suavização do ImGui as arredonda de
      -- jeitos diferentes — foi visto isso deixando a borda de cima
      -- visivelmente mais grossa que a da esquerda.
      local BORDA_LOG = 1
      local larguraLog = math.floor(ImGui.GetContentRegionAvail(ctx))
      local alturaLog = 220
      local logX, logY = ImGui.GetCursorScreenPos(ctx)
      logX, logY = math.floor(logX), math.floor(logY)

      local nBordaLog = empilhaFundo(0x2A2F3AFF)
      if ImGui.BeginChild(ctx, '##registroBorda', larguraLog, alturaLog) then
        ImGui.EndChild(ctx)
      end
      if nBordaLog > 0 then pcall(ImGui.PopStyleColor, ctx, 1) end

      ImGui.SetCursorScreenPos(ctx, logX + BORDA_LOG, logY + BORDA_LOG)
      local nFundoLog = empilhaFundo(0x0F1116FF)
      if ImGui.BeginChild(ctx, 'registro',
                          larguraLog - 2 * BORDA_LOG, alturaLog - 2 * BORDA_LOG) then
        -- Recuo interno: sem isso o texto ficava colado na borda do
        -- campo. Dummy dá a margem de cima; Indent/Unindent dá a
        -- margem da esquerda em TODAS as linhas do laço — SetCursorPos
        -- sozinho só posicionaria a primeira, porque cada Text() que
        -- termina uma linha volta o X pro início do conteúdo, não pro
        -- ponto que foi setado à mão.
        ImGui.Dummy(ctx, 1, 6)
        ImGui.Indent(ctx, 8)
        if #painel.linhas == 0 then
          ImGui.TextColored(ctx, 0x666E7AFF,
            'Sem registros ainda. As ações aparecem aqui conforme acontecem.')
        end
        for i = 1, #painel.linhas do
          ImGui.TextColored(ctx, 0xAAB4C2FF, painel.linhas[i])
        end
        ImGui.Unindent(ctx, 8)
        if ImGui.SetScrollHereY and #painel.linhas > 0 then
          pcall(ImGui.SetScrollHereY, ctx, 1.0)
        end
        ImGui.EndChild(ctx)
      end
      if nFundoLog > 0 then pcall(ImGui.PopStyleColor, ctx, 1)
      end
    end

  elseif abaAtual == 'sobre' then
    ImGui.Dummy(ctx, 1, 8)

    -- Ícone grande ao lado do nome. Desenhado antes do texto e o cursor
    -- posicionado à direita dele — mesma técnica da barra de título, já
    -- que o ícone é DrawList e o nome é um item do ImGui, e os dois não
    -- se alinham sozinhos numa linha.
    local ICONE = 40
    local ix, iy = ImGui.GetCursorScreenPos(ctx)
    ix, iy = math.floor(ix), math.floor(iy)
    desenharIconeApp(ImGui.GetWindowDrawList(ctx), ix, iy, ICONE,
      recording and Theme.UI.rec or nil)

    ImGui.SetCursorScreenPos(ctx, ix + ICONE + 14, iy + 1)
    local comFonte = Theme.pushFont(ImGui, ctx, state.fonts, 26)
    -- Altura MEDIDA com a fonte grande já empurrada. Antes havia um 24
    -- fixo aqui, menor que a altura real da linha em 26pt: a versão
    -- subia e ficava por cima do nome.
    local _, alturaNome = ImGui.CalcTextSize(ctx, Version.NOME)
    ImGui.TextColored(ctx, Theme.UI.text, Version.NOME)
    if comFonte then ImGui.PopFont(ctx) end

    ImGui.SetCursorScreenPos(ctx, ix + ICONE + 14, iy + 1 + alturaNome + 2)
    -- A COMPILAÇÃO NA MESMA LINHA DA VERSÃO.
    --
    -- O número de versão não responde "é esta a compilação que acabei de
    -- receber?" — ele só muda quando alguém decide mudá-lo. A hora da
    -- compilação muda sempre, e é ela que separa "o conserto não
    -- funcionou" de "o conserto não chegou".
    --
    -- Na MESMA linha e não numa terceira: as duas que já existem
    -- terminam coladas na base do ícone, e uma terceira cairia por cima
    -- do que vem abaixo.
    ImGui.TextColored(ctx, Theme.UI.accent, ('versão %s   ·   %s')
      :format(Version.numero(), Version.COMPILACAO or 'desconhecida'))

    -- Cursor de volta abaixo do ícone, que é mais alto que as duas
    -- linhas de texto ao lado.
    ImGui.SetCursorScreenPos(ctx, ix, iy + ICONE + 4)

    ImGui.Dummy(ctx, 1, 14)
    grupo('O QUE É')
    ImGui.TextColored(ctx, 0x8A93A3FF,
      'Programação de iluminação dentro do REAPER, usando o mesmo layout da\n'
      .. 'Janela Personalizada do Lumikit Show. Lê o arquivo .form —\n'
      .. 'a Tela Personalizada —, reconstrói\n'
      .. 'a tela, envia MIDI ao clicar e grava a operação na timeline — para a\n'
      .. 'luz acompanhar a música na hora do show.')

    -- --------------------------------------------------- atualização
    ImGui.Dummy(ctx, 1, 14)
    grupo('ATUALIZAÇÃO')

    local at = painel.atualizacao
    if ImGui.Button(ctx, 'Procurar atualizações', 190, 26) then
      at.ocupado, at.achada, at.recado = true, nil, 'procurando...'
    end

    if at.achada then
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, 'Baixar e instalar', 160, 26) then
        at.ocupado, at.recado = true, 'baixando...'
        at.instalar = true
      end
    end

    if at.recado then
      ImGui.Dummy(ctx, 1, 6)
      ImGui.TextColored(ctx,
        at.achada and Theme.UI.accent or 0x8A93A3FF, at.recado)
    end
    if at.achada and at.achada.notas and at.achada.notas ~= '' then
      ImGui.TextColored(ctx, 0x777F8CFF, at.achada.notas)
    end
    if Version.MANIFESTO == '' then
      ImGui.TextColored(ctx, 0x5F6672FF,
        'A procura por atualizações ainda não está configurada.')
    end

    ImGui.Dummy(ctx, 1, 10)
    grupo('DESENVOLVIMENTO')
    ajuste('Desenvolvedor', nil, 220)
    ImGui.TextColored(ctx, Theme.UI.text, Version.AUTOR)

    ajuste('Interface', nil, 220)
    ImGui.TextColored(ctx, Theme.UI.textDim, 'ReaImGui (ReaPack)')

    ImGui.Dummy(ctx, 1, 10)
    grupo('SOBRE A NUMERAÇÃO')
    ImGui.TextColored(ctx, 0x8A93A3FF,
      'MAIOR.MENOR.CORREÇÃO — o número diz o que mudou:\n'
      .. 'a primeira parte muda quando algo grande muda de forma, a segunda\n'
      .. 'quando entra um recurso novo, a terceira num conserto de defeito.')
  end

end


local function trazerParaFrente()
  local hwnd = acharJanelaPropria()
  if hwnd and reaper.BR_Win32_SetForegroundWindow then
    pcall(reaper.BR_Win32_SetForegroundWindow, hwnd)
  end
end

--- Devolve o foco do teclado à janela do LumiBridge.
--
--  POR QUE PRECISA EXISTIR: as ações de transporte do REAPER
--  (Main_OnCommand) puxam o foco para a janela principal dele. O
--  handleShortcuts sai logo na primeira linha quando a janela não está
--  focada, então o primeiro Enter tocava e, dali em diante, nenhum
--  atalho era mais visto — o sintoma exato relatado: "funciona uma vez
--  e depois só com Ctrl+Espaço" (Ctrl+Espaço voltava a funcionar
--  porque, para usá-lo, o usuário clicava na janela antes).
--
--  Só é chamada logo depois de um atalho NOSSO ter sido atendido, ou
--  seja, num quadro em que a janela comprovadamente tinha o foco. Não é
--  roubo de foco: é devolver o que a ação do REAPER acabou de levar.
local function devolverFoco()
  local hwnd = acharJanelaPropria()
  if hwnd and reaper.BR_Win32_SetFocus then
    pcall(reaper.BR_Win32_SetFocus, hwnd)
  end
end

--- Área útil do monitor onde a janela está agora.
--
--  NO MONITOR CERTO, e é esse o ponto todo. Com duas telas, maximizar
--  sempre na principal jogaria a janela para fora de onde o usuário
--  estava trabalhando — que é justamente o arranjo em que maximizar mais
--  serve: LumiBridge numa tela, editor MIDI na outra.
--
--  MyGetViewport responde "qual monitor contém este retângulo", então
--  basta perguntar pelo retângulo da própria janela. Pedimos a área de
--  TRABALHO (wantWorkArea), não a tela inteira: cobrir a barra de
--  tarefas esconderia o botão de voltar para o REAPER.
--
--  @return x, y, largura, altura — ou nil se a API não existir
local function areaDoMonitor(jx, jy, jw, jh)
  local x1, y1 = jx + jw, jy + jh

  --- Aceita um retângulo só se ele for de tela mesmo.
  local function valida(l, t, r, b, comoVeio)
    if type(l) ~= 'number' or type(b) ~= 'number' then return nil end
    if r - l < 200 or b - t < 200 then return nil end
    log(('monitor lido por %s: %d,%d %dx%d')
      :format(comoVeio, l, t, r - l, b - t))
    return l, t, r - l, b - t
  end

  -- DUAS FORMAS DE CHAMAR, porque a ligação Lua do MyGetViewport tem os
  -- quatro primeiros parâmetros como ENTRADA E SAÍDA — e passá-los ou
  -- não é a diferença entre a resposta certa e um erro que o pcall
  -- engole. Engolido, o botão simplesmente não fazia nada: nem
  -- funcionava, nem dizia por quê.
  if reaper.MyGetViewport then
    local ok, l, t, r, b = pcall(reaper.MyGetViewport,
      0, 0, 0, 0, jx, jy, x1, y1, true)
    if ok then
      local a, c, d, e = valida(l, t, r, b, 'MyGetViewport')
      if a then return a, c, d, e end
    end

    ok, l, t, r, b = pcall(reaper.MyGetViewport, jx, jy, x1, y1, true)
    if ok then
      local a, c, d, e = valida(l, t, r, b, 'MyGetViewport (forma curta)')
      if a then return a, c, d, e end
    end
  end

  -- Reserva pelo SWS, que a maioria das instalações tem.
  if reaper.BR_Win32_GetMonitorRectFromRect then
    local ok, l, t, r, b = pcall(reaper.BR_Win32_GetMonitorRectFromRect,
      true, jx, jy, x1, y1)
    if ok then
      local a, c, d, e = valida(l, t, r, b, 'SWS')
      if a then return a, c, d, e end
    end
  end

  log('nenhuma API de monitor respondeu: MyGetViewport '
    .. (reaper.MyGetViewport and 'existe' or 'não existe')
    .. ', BR_Win32_GetMonitorRectFromRect '
    .. (reaper.BR_Win32_GetMonitorRectFromRect and 'existe' or 'não existe'))
  return nil
end

--- Barra de título PRÓPRIA, no lugar da decoração padrão do ImGui.
--
--  Por que trocar: a barra do ImGui trazia dois controles que não
--  serviam aqui. O triângulo de "collapse" escondia tudo menos a
--  própria barra de título, e não minimizava nada de fato — no lugar
--  dele há o botão de minimizar, que esconde a janela para valer (ver
--  minimizarJanela). E o X era o botão genérico do ImGui, destoando de
--  uma interface inteira desenhada à mão.
--
--  O CUSTO: sem a barra do ImGui, a janela não se arrasta sozinha. O
--  arrasto é feito aqui, na mão, guardando a distância entre o mouse e
--  o canto da janela no momento do clique e reposicionando a janela por
--  essa distância enquanto o botão fica pressionado. Guardar o OFFSET,
--  e não o delta quadro a quadro, é o que impede a janela de "escorregar"
--  do cursor quando um quadro demora mais que os outros.
--
--  @return altura ocupada
--- Lê a licença guardada e decide se o programa abre.
--
--  Chamada uma vez, ao iniciar. Sem chave válida, a janela mostra a tela
--  de ativação no lugar de tudo (ver `chrome.telaDeAtivacao`).
function chrome.lerLicenca()
  local Lic = require('core.licenca')
  chrome.lic.codigo = Lic.codigoDaMaquina()
  local guardada = reaper.GetExtState(EXT_SECTION, 'licenca')
  chrome.lic.tipo = guardada ~= '' and Lic.tipoDaChave(guardada) or nil
  chrome.lic.ativa = chrome.lic.tipo ~= nil
  -- Último dia do mês: some um mês e volta um dia.
  if chrome.lic.tipo == 'mestra' then
    local agora = os.date('*t')
    local fim = os.time({ year = agora.year, month = agora.month + 1,
                          day = 1, hour = 12 }) - 86400
    chrome.lic.venceEm = os.date('%d/%m', fim)
  else
    chrome.lic.venceEm = nil
  end
  -- CONFERE DE NOVO A CADA ABERTURA, e não confia num "sim" gravado.
  -- Copiar a pasta de configurações do REAPER para outro computador
  -- levaria a chave junto; conferindo contra a máquina, ela não vale lá.
  return chrome.lic.ativa
end

--- A tela de ativação, no lugar do programa.
--
--  Método de `chrome`, e não função local: o corpo deste módulo está no
--  teto de 200 locais do Lua.
--
--  O QUE ELA PRECISA FAZER BEM é uma coisa só: o código chegar inteiro
--  até o vendedor. Por isso o botão de copiar — oito dígitos ditados por
--  telefone ou digitados à mão erram, e cada erro é uma ida e volta de
--  WhatsApp que ninguém entende.
function chrome.telaDeAtivacao()
  local Lic = require('core.licenca')
  local dl = ImGui.GetWindowDrawList(ctx)
  local bx, by = ImGui.GetCursorScreenPos(ctx)
  bx, by = math.floor(bx), math.floor(by)

  -- UM CARTÃO CENTRADO, e não uma coluna encostada na margem.
  --
  -- Esta é a primeira tela que o cliente vê do programa que ele acabou
  -- de comprar. Texto solto no canto superior esquerdo parece um erro;
  -- um cartão no meio da janela parece uma etapa.
  local janelaW, janelaH = ImGui.GetWindowSize(ctx)
  local CARTAO, ALTURA = 470, 392
  local cx = bx + math.max(20, math.floor(((janelaW or 900) - CARTAO) * 0.5))
  local cy = by + math.max(16, math.floor(((janelaH or 600) - ALTURA) * 0.30))

  ImGui.DrawList_AddRectFilled(dl, cx, cy, cx + CARTAO, cy + ALTURA,
                               Theme.UI.panel, 12)
  ImGui.DrawList_AddRect(dl, cx, cy, cx + CARTAO, cy + ALTURA,
                         0x3F4654FF, 12, 0, 1)

  local px = cx + 30            -- margem interna do cartão
  local y  = cy + 26

  -- ---------------------------------------------------------- cabeçalho
  desenharIconeApp(dl, px, y, 34)
  ImGui.SetCursorScreenPos(ctx, px + 48, y - 2)
  local f1 = Theme.pushFont(ImGui, ctx, state.fonts, 22)
  ImGui.TextColored(ctx, Theme.UI.text, 'Ativação')
  if f1 then ImGui.PopFont(ctx) end
  ImGui.SetCursorScreenPos(ctx, px + 48, y + 24)
  ImGui.TextColored(ctx, 0x777F8CFF,
                    Version.NOME .. ' ' .. Version.numero())

  y = y + 58
  ImGui.DrawList_AddLine(dl, px, y, cx + CARTAO - 30, y, 0x2A2E37FF, 1)
  y = y + 24

  --- Bolinha numerada. São dois passos, e o cliente vê que são dois.
  local function passoNumerado(n, texto, yy)
    ImGui.DrawList_AddCircleFilled(dl, px + 9, yy + 9, 9, 0x2B3B57FF)
    ImGui.SetCursorScreenPos(ctx, px + 6, yy + 2)
    ImGui.TextColored(ctx, Theme.UI.accent, tostring(n))
    ImGui.SetCursorScreenPos(ctx, px + 28, yy + 2)
    ImGui.TextColored(ctx, 0xB9C0CCFF, texto)
  end

  -- ------------------------------------------------------------ passo 1
  passoNumerado(1, 'Mande este código a quem lhe vendeu o LumiBridge', y)
  y = y + 32

  local codigo = chrome.lic.codigo
  local CAIXA = 232
  ImGui.DrawList_AddRectFilled(dl, px + 28, y, px + 28 + CAIXA, y + 44,
                               0x14171CFF, 8)
  ImGui.DrawList_AddRect(dl, px + 28, y, px + 28 + CAIXA, y + 44,
                         0x3A4150FF, 8, 0, 1)
  ImGui.SetCursorScreenPos(ctx, px + 44, y + 12)
  local f2 = Theme.pushFont(ImGui, ctx, state.fonts, 20)
  ImGui.TextColored(ctx, codigo and Theme.UI.accent or Theme.UI.warn,
                    codigo or 'máquina não identificada')
  if f2 then ImGui.PopFont(ctx) end

  if codigo then
    ImGui.SetCursorScreenPos(ctx, px + 28 + CAIXA + 14, y + 6)
    if ImGui.Button(ctx, 'Copiar código', 128, 32) then
      local copiar = Compat.get(ImGui, 'SetClipboardText')
      if copiar then pcall(copiar, ctx, codigo) end
      chrome.lic.erro = nil
      chrome.lic.aviso = 'Código copiado. Cole no WhatsApp.'
    end
  end

  y = y + 64

  -- ------------------------------------------------------------ passo 2
  passoNumerado(2, 'Digite aqui a chave que ele responder', y)
  y = y + 32

  ImGui.SetCursorScreenPos(ctx, px + 28, y + 6)
  ImGui.SetNextItemWidth(ctx, CAIXA)
  local mudou, texto = ImGui.InputText(ctx, '##chave', chrome.lic.digitada)
  if ImGui.IsItemActive(ctx) then campoTextoAtivo = true end
  if mudou then
    chrome.lic.digitada = texto
    chrome.lic.erro, chrome.lic.aviso = nil, nil
  end

  ImGui.SetCursorScreenPos(ctx, px + 28 + CAIXA + 14, y + 4)
  if ImGui.Button(ctx, 'Ativar', 128, 32) then
    if Lic.confere(chrome.lic.digitada) then
      reaper.SetExtState(EXT_SECTION, 'licenca',
                         Lic.formatar(chrome.lic.digitada), true)
      chrome.lic.erro, chrome.lic.aviso = nil, nil
      chrome.lerLicenca()   -- reaproveita a leitura: tipo e vencimento
      log(chrome.lic.tipo == 'mestra'
        and 'aberto na CHAVE MESTRA — vence na virada do mês'
        or  'licença ativada nesta máquina')
    else
      chrome.lic.aviso = nil
      chrome.lic.erro = 'Esta chave não vale nesta máquina.'
    end
  end

  y = y + 50

  -- ------------------------------------------------------------ recado
  --
  -- Em lugar FIXO, e não empurrando o resto para baixo. Uma mensagem que
  -- aparece e some mexendo na posição dos botões faz a mão errar o alvo
  -- justamente na segunda tentativa, que é quando ela já está irritada.
  if chrome.lic.erro then
    ImGui.SetCursorScreenPos(ctx, px + 28, y)
    ImGui.TextColored(ctx, Theme.UI.warn, chrome.lic.erro)
    ImGui.SetCursorScreenPos(ctx, px + 28, y + 18)
    ImGui.TextColored(ctx, 0x777F8CFF,
      'Confira se o código enviado foi o que está aí em cima.')
  elseif chrome.lic.aviso then
    ImGui.SetCursorScreenPos(ctx, px + 28, y)
    ImGui.TextColored(ctx, 0x46D07AFF, chrome.lic.aviso)
  end

  -- ------------------------------------------------------------- rodapé
  local yr = cy + ALTURA - 62
  ImGui.DrawList_AddLine(dl, px, yr, cx + CARTAO - 30, yr, 0x2A2E37FF, 1)
  ImGui.SetCursorScreenPos(ctx, px, yr + 14)
  ImGui.TextColored(ctx, 0x5F6672FF,
    'A chave vale só nesta máquina, para sempre, e nunca precisa de\n'
    .. 'internet. Se você formatar o computador, peça outra.')

  -- O cursor de layout sai de baixo do cartão: o que vier depois desenha
  -- a partir dele, e não por cima.
  ImGui.SetCursorScreenPos(ctx, bx, cy + ALTURA + 20)
  ImGui.Dummy(ctx, 1, 1)
end
local function drawBarraTitulo()
  local ALTURA = 30
  local largura = ImGui.GetContentRegionAvail(ctx)
  local x0, y0 = ImGui.GetCursorScreenPos(ctx)
  x0, y0 = math.floor(x0), math.floor(y0)
  local dl = ImGui.GetWindowDrawList(ctx)

  -- A BARRA COLA NA BORDA DA JANELA, não na área de conteúdo.
  --
  -- O ImGui reserva um espaçamento interno (WindowPadding) em volta de
  -- todo o conteúdo, e desenhar a barra dentro dele deixava uma moldura
  -- da cor do fundo em cima e dos lados. Numa janela com barra de título
  -- própria isso lê como falha de acabamento — e maximizada, com a barra
  -- descolada dos cantos da tela, fica gritante.
  --
  -- O RETÂNGULO ignora o espaçamento e vai até a borda de verdade; os
  -- BOTÕES e o texto continuam posicionados pelo conteúdo, para não
  -- encostarem no canto.
  local jx, jy = ImGui.GetWindowPos(ctx)
  local jw = ImGui.GetWindowSize(ctx)
  local bx0 = math.floor(jx or x0)
  local by0 = math.floor(jy or y0)
  local bx1 = bx0 + math.floor(jw or largura)

  ImGui.DrawList_AddRectFilled(dl, bx0, by0, bx1, y0 + ALTURA, 0x1A1D23FF)
  ImGui.DrawList_AddLine(dl, bx0, y0 + ALTURA, bx1, y0 + ALTURA, 0x22252CFF, 1)

  -- ÁREA DE ARRASTO: tudo menos o espaço dos três botões à direita.
  local BOTAO_W, BOTAO_H = 26, 22
  local larguraArrasto = math.max(1, largura - (BOTAO_W * 3 + 18))
  ImGui.SetCursorScreenPos(ctx, x0, y0)
  ImGui.InvisibleButton(ctx, '##arrastarJanela', larguraArrasto, ALTURA)

  -- DUPLO CLIQUE MINIMIZA, como em qualquer janela. Conferido ANTES do
  -- arrasto: o duplo clique também deixa o item ativo, e sem sair aqui
  -- o segundo clique iniciaria um arrasto de um pixel antes de
  -- minimizar.
  --
  -- IsMouseDoubleClicked sondada por Compat.get, nunca acessada direto:
  -- o shim do ReaImGui LANÇA ERRO num campo inexistente (ver
  -- PROJECT_CONTEXT.md), então `if ImGui.IsMouseDoubleClicked then`
  -- seria o que derrubaria o script numa versão que não a tenha.
  local duploClique = Compat.get(ImGui, 'IsMouseDoubleClicked')
  if duploClique and ImGui.IsItemHovered(ctx) then
    local ok, foi = pcall(duploClique, ctx, 0)
    if ok and foi then
      local jw, jh = ImGui.GetWindowSize(ctx)
      chrome.normalW, chrome.normalH = jw, jh
      chrome.minimizado = true
      chrome.pendW, chrome.pendH = 54, 42
      encaixe.w = 0
      chrome.arrastando = false
      return ALTURA
    end
  end

  if ImGui.IsItemActive and ImGui.IsItemActive(ctx) then
    local mx, my = ImGui.GetMousePos(ctx)
    local wx, wy = ImGui.GetWindowPos(ctx)
    if not chrome.arrastando then
      chrome.arrastando = true
      chrome.offX, chrome.offY = mx - wx, my - wy
    end
    if ImGui.SetWindowPos then
      pcall(ImGui.SetWindowPos, ctx, mx - chrome.offX, my - chrome.offY)
    end
  else
    chrome.arrastando = false
  end

  -- O ÍCONE DO PROGRAMA, o mesmo da pastilha do chrome.minimizado: é o que
  -- identifica a janela de relance. Fica vermelho gravando, então
  -- continua servindo de indicador de estado, que era o papel do
  -- quadradinho que havia aqui antes.
  local TAM_ICONE = 22
  desenharIconeApp(dl, x0 + 9, y0 + (ALTURA - TAM_ICONE) * 0.5, TAM_ICONE,
    recording and Theme.UI.rec or nil)

  ImGui.SetCursorScreenPos(ctx, x0 + 9 + TAM_ICONE + 9, y0 + 6)
  ImGui.TextColored(ctx, 0xC7CDD8FF, Version.NOME)
  ImGui.SameLine(ctx)
  ImGui.TextColored(ctx, 0x454B57FF, Version.numero())

  -- ABERTO NA CHAVE MESTRA? DIZ, e diz onde não dá para não ver.
  --
  -- A mestra vence na virada do mês. O pior desfecho dela seria uma
  -- máquina de cliente ficando na chave do desenvolvedor sem ninguém
  -- notar — e descobrindo isso quando ela vencer, no meio de um show.
  if chrome.lic.tipo == 'mestra' then
    ImGui.SameLine(ctx)
    ImGui.Dummy(ctx, 6, 1)
    ImGui.SameLine(ctx)
    local mx0, my0 = ImGui.GetCursorScreenPos(ctx)
    local largura = 128
    ImGui.DrawList_AddRectFilled(dl, mx0, my0 - 1, mx0 + largura,
                                 my0 + 16, 0x4A3A12FF, 4)
    ImGui.SetCursorScreenPos(ctx, mx0 + 7, my0)
    ImGui.TextColored(ctx, Theme.UI.warn,
      ('CHAVE MESTRA · %s'):format(chrome.lic.venceEm or ''))
  end

  -- BOTÕES: minimizar e fechar, desenhados como o resto da interface.
  local by = y0 + (ALTURA - BOTAO_H) * 0.5

  local function botaoBarra(id, bx, desenhar, dicaTexto, perigo)
    ImGui.SetCursorScreenPos(ctx, bx, by)
    ImGui.InvisibleButton(ctx, id, BOTAO_W, BOTAO_H)
    local sobre = ImGui.IsItemHovered(ctx)
    local clicou = ImGui.IsItemClicked(ctx)
    if sobre then
      ImGui.DrawList_AddRectFilled(dl, bx, by, bx + BOTAO_W, by + BOTAO_H,
        perigo and Theme.UI.rec or Theme.UI.panelHover, 4)
      if dicaTexto then dicaSe( dicaTexto) end
    end
    desenhar(bx + BOTAO_W * 0.5, by + BOTAO_H * 0.5,
      sobre and 0xFFFFFFFF or 0x9199A6FF)
    return clicou
  end

  local bxMinimizar = x0 + largura - (BOTAO_W * 3 + 14)
  local bxMaximizar = x0 + largura - (BOTAO_W * 2 + 10)
  local bxFechar    = x0 + largura - (BOTAO_W + 6)

  -- MINIMIZAR — a janela encolhe até virar uma pastilha com o ícone.
  --
  -- Duas tentativas anteriores foram descartadas em uso: o "collapse"
  -- do ImGui (escondia tudo menos a barra de título) e o minimizar do
  -- Windows via SWS (a janela é filha da do REAPER, então virava um
  -- tocinho de barra nativa no canto inferior — destoando de tudo).
  -- Encolher é o único caminho em que a aparência continua sendo nossa
  -- E a janela continua visível pra ser clicada de volta.
  if botaoBarra('##btMinimizar', bxMinimizar, function(cx, cy, cor)
      ImGui.DrawList_AddLine(dl, cx - 5, cy + 4, cx + 5, cy + 4, cor, 1.4)
    end,
    'Minimizar\n\nA janela vira uma pastilha com o ícone, que você arrasta\n'
    .. 'para onde quiser. Clique nela para voltar ao tamanho normal.') then
    local jw, jh = ImGui.GetWindowSize(ctx)
    chrome.normalW, chrome.normalH = jw, jh
    chrome.minimizado = true
    chrome.pendW, chrome.pendH = 54, 42
    encaixe.w = 0   -- a área muda de tamanho: recalcula a escala
  end

  -- MAXIMIZAR — enche a área útil do monitor, e restaura de volta.
  --
  -- O tamanho e a posição de antes são guardados para o clique seguinte
  -- devolver a janela EXATAMENTE onde ela estava, e não a um tamanho
  -- padrão qualquer. É o que se espera de um maximizar.
  --
  -- Ele NÃO é o duplo clique na barra: ali o duplo clique minimiza, a
  -- pedido — o contrário do costume do Windows, mas foi o combinado.
  local iconeMax = function(cx, cy, cor)
    if maxi.on then
      -- Dois quadrados sobrepostos: o desenho universal de "restaurar".
      ImGui.DrawList_AddRect(dl, cx - 5, cy - 2, cx + 2, cy + 5, cor, 0, 0, 1.3)
      ImGui.DrawList_AddRect(dl, cx - 2, cy - 5, cx + 5, cy + 2, cor, 0, 0, 1.3)
    else
      ImGui.DrawList_AddRect(dl, cx - 5, cy - 5, cx + 5, cy + 5, cor, 0, 0, 1.3)
    end
  end

  if botaoBarra('##btMaximizar', bxMaximizar, iconeMax,
    maxi.on
      and 'Restaurar\n\nVolta ao tamanho e à posição de antes.'
      or  'Maximizar\n\nEnche a tela em que a janela está agora.\n'
          .. 'Com dois monitores, arraste a janela para o outro antes:\n'
          .. 'ela maximiza no monitor onde estiver.') then
    if maxi.on then
      if maxi.w then
        chrome.pendW, chrome.pendH = maxi.w, maxi.h
        if ImGui.SetWindowPos and maxi.x then
          pcall(ImGui.SetWindowPos, ctx, maxi.x, maxi.y)
        end
      end
      maxi.on = false
      encaixe.w = 0
    else
      local jx, jy = ImGui.GetWindowPos(ctx)
      local jw, jh = ImGui.GetWindowSize(ctx)
      local mx, my, mw, mh = areaDoMonitor(jx, jy, jw, jh)
      if mw then
        maxi.x, maxi.y = jx, jy
        maxi.w, maxi.h = jw, jh
        if ImGui.SetWindowPos then pcall(ImGui.SetWindowPos, ctx, mx, my) end
        chrome.pendW, chrome.pendH = mw, mh
        maxi.on = true
        encaixe.w = 0
      else
        -- Sem a API do monitor não dá para adivinhar o tamanho da tela, e
        -- chutar deixaria a janela pela metade ou fora dela. Dizer por
        -- que não funcionou é melhor que um botão que não faz nada.
        log('maximizar indisponível: esta versão do REAPER não informa a '
          .. 'área do monitor')
      end
    end
  end

  -- FECHAR pede confirmação DURANTE A GRAVAÇÃO, e só nela: fechar sem
  -- querer no meio de uma música perderia o trabalho em curso. Parado,
  -- confirmar a cada fechamento seria só atrito.
  if botaoBarra('##btFechar', bxFechar, function(cx, cy, cor)
      ImGui.DrawList_AddLine(dl, cx - 5, cy - 5, cx + 5, cy + 5, cor, 1.4)
      ImGui.DrawList_AddLine(dl, cx + 5, cy - 5, cx - 5, cy + 5, cor, 1.4)
    end, 'Fechar o LumiBridge', true) then
    if recording then
      local r = reaper.MB(
        'A gravação está ligada. Fechar agora encerra o LumiBridge.\n\n'
        .. 'Fechar mesmo assim?', 'LumiBridge', 4)
      if r == 6 then chrome.fechar = true end
    else
      chrome.fechar = true
    end
  end

  ImGui.SetCursorScreenPos(ctx, x0, y0 + ALTURA + 4)
  return ALTURA + 4
end

local function drawToolbar()
  -- O TRANSPORTE E A FORMA DE ONDA SÃO SEMPRE VISÍVEIS.
  --
  -- Precisam vir ANTES do corte das configurações: já uma vez um
  -- `return` levou junto o transporte inteiro, porque ele era desenhado
  -- mais adiante nesta mesma função.
  local tBarra = cronometro()
  drawTransportBar()
  medir('barra', tBarra)

  drawAvisos()

  local tOnda = cronometro()
  -- COM AS FAIXAS AO LADO, a onda se muda para o topo da coluna delas
  -- (ver drawFaixas). É lá que ela serve de régua: um instante da música
  -- fica na mesma coluna de pixels na onda e no que está gravado. Aqui
  -- em cima, atravessando a janela toda, ela não se alinha com nada —
  -- e o .form ainda ganha os 58px de altura de volta.
  if not (faixas.abertas and faixas.lado and not faixas.inteira) then
    drawTimeline()
  end
  medir('onda', tOnda)

  -- AS CONFIGURAÇÕES SAÍRAM DAQUI.
  --
  -- Desenhadas nesta barra, elas empurravam o layout para baixo e os
  -- botões encolhiam. Agora ficam num painel flutuando por CIMA do
  -- canvas (ver drawSettingsPanel, chamada no fim de `frame`): o layout
  -- continua do tamanho normal atrás, só parcialmente coberto à
  -- direita, e fechar devolve a tela inteira como estava.
end

--- Avisos e detalhes, mostrados na janela PRINCIPAL.
--
--  Ficam fora das configurações de propósito: um erro escondido atrás
--  de uma janela fechada é um erro que ninguém vê.
function drawAvisos()
  -- Avisos ficam FORA das seções: um erro escondido atrás de um painel
  -- fechado é um erro que ninguém vê.
  if loadError then
    ImGui.TextColored(ctx, 0xFF6666FF, loadError)
  end
  if auditWarning then
    ImGui.TextColored(ctx, 0xFFCC55FF, auditWarning)
  end

  if opcoes.detalhes then
    local e = state.hovered
    if e then
      local midi = (e.commands and e.commands[1])
        and Model.describeCommand(e.commands[1]) or 'sem MIDI'
      local groups = (session and e.tag)
        and Rules.describe(session.ruleIndex, e.tag) or '—'
      local key = e.key and (' | tecla ' .. (Compat.keyName(e.key) or '?')) or ''
      ImGui.TextColored(ctx, 0x88CCFFFF, ('%s  tag=%s  %dx%d  |  %s  |  %s%s')
        :format(e.text or e.kind, tostring(e.tag), e.w, e.h, midi, groups, key))
    else
      ImGui.TextColored(ctx, 0x777F8CFF, 'Passe o cursor sobre um controle.')
    end
  end
end

-- ------------------------------------------------------- gravação

local function refreshTracks()
  tracks = Timeline.listTracks()
end

--- Restaura a track pelo NOME, não pelo índice: reordenar as tracks do
--  projeto mudaria o índice e a gravação iria parar na track errada.
local function restoreTrack()
  refreshTracks()
  local saved = reaper.GetExtState(EXT_SECTION, EXT_TRACK)
  local t = Timeline.findTrackByName(saved)
  if t then Timeline.setTrack(t.index, t.name) end

  local off = tonumber(reaper.GetExtState(EXT_SECTION, EXT_OFFSET))
  if off then latency = off end
end

--- Posição musical atual, já descontado o atraso de reação.
function context()
  local ctx = Timeline.context(latency)
  if recorder then Recorder.setGrid(recorder, ctx.gridQN) end
  return ctx
end

--- Converte as mudanças de estado em notas e as escreve.
local function record(intents, ctx)
  if not recording or not recorder or not Timeline.isReady() then return end

  local produced = {}
  for _, it in ipairs(intents) do
    if it.action == 'state' and it.element then
      local out
      if not ctx.playing then
        -- PARADO: clicar apenas MARCA o botão, não grava nada.
        --
        -- É assim que se define o estado inicial da música: você marca
        -- os botões com que ela começa e, ao dar play, eles são gravados
        -- de uma vez a partir da SEGUNDA célula, depois do release.
        --
        -- Antes cada clique virava uma nota no cursor, que caía no
        -- primeiro quadradinho — justamente a célula reservada ao
        -- release, e antes da hora.
        out = nil
      elseif it.on then
        -- Altura do próprio controle.
        local propria
        for _, cmd in ipairs(it.element.commands or {}) do
          if (cmd.status & 0xF0) == 0x90 then propria = cmd.data1 break end
        end

        -- O CONTROLE JÁ ESTÁ SOANDO? Então a nota dele é ADOTADA, não
        -- recriada.
        --
        -- Cortar e abrir outra na mesma altura deixa uma emenda visível
        -- e, pior, um segundo Note On — que num controle toggle APAGA a
        -- luz no meio da música.
        local soando = Timeline.soundingAt(ctx.time)
        local jaSoa = propria and soando[propria] == true

        -- Corta as RIVAIS sempre; a própria, só se ainda não estiver
        -- soando (aí é uma nota velha que precisa terminar aqui).
        local alvos = {}
        for p in pairs(it.element.rivalPitches or {}) do alvos[p] = true end
        if propria and not jaSoa then alvos[propria] = true end

        if next(alvos) then
          local n = Timeline.truncatePitchesAt(ctx.time, alvos)
          if n and n > 0 then
            log(('  cortou %d nota(s) em %.3f s'):format(n, ctx.time))
          end
        end

        if jaSoa then
          -- Assume a nota existente e continua esticando a MESMA.
          local starts = {}
          for _, a in ipairs(Timeline.adoptAt(ctx.time)) do
            if a.pitch == propria then
              starts[it.element.tag] = a.startQN
              Timeline.claimLive(it.element.tag, a.index)
            end
          end
          out = Recorder.resume(recorder, { it.element }, ctx.qn, starts)
          log(('  adotou a nota %d que já soava'):format(propria))
        else
          out = Recorder.noteOn(recorder, it.element, ctx.qn)
        end
      else
        out = Recorder.noteOff(recorder, it.element, ctx.qn, it.byRule)
      end
      for _, x in ipairs(out or {}) do produced[#produced + 1] = x end
    end
  end

  if #produced > 0 then
    Timeline.write(produced)
    for _, it in ipairs(produced) do
      log(('  %s nota %-3s  %.3f -> %.3f QN  vel %s')
        :format(it.kind == 'update' and 'fecha' or 'abre ',
                tostring(it.pitch), it.startQN or 0, it.endQN or 0,
                tostring(it.velocity or 127)))
    end
  end
end

local function recordFader(element, value, ctx)
  if not recording or not recorder or not Timeline.isReady() then return end
  local out = Recorder.fader(recorder, element, ctx.qn, value)
  if #out > 0 then Timeline.write(out) end
end

-- ~12x por segundo: rápido o bastante pro traço da automação aparecer
-- crescendo em tempo real no REAPER, sem chamar a API a cada quadro
-- (30-60x/s) durante o arrasto inteiro.
local LIVE_WRITE_INTERVAL = 0.08

--- Escreve o ponto ATUAL do gesto na timeline sem esperar você soltar
--  o fader — mas só de vez em quando (LIVE_WRITE_INTERVAL), não a cada
--  leitura.
--
--  É só um RASCUNHO visual: quando o gesto fecha, Curve.polish +
--  Timeline.clearCCRange (mais abaixo) apagam esses pontos
--  intermediários e escrevem a versão simplificada por cima. As duas
--  bordas do gesto (onde você pegou e onde soltou o fader) sobrevivem
--  à limpeza por coincidirem com a posição exata dos pontos finais —
--  o dedup de posição do próprio Timeline.write (M7.3) resolve ali.
local function liveWriteFader(mov, ctx, value)
  local agora = reaper.time_precise and reaper.time_precise() or 0
  if agora - (mov.lastLiveWrite or 0) < LIVE_WRITE_INTERVAL then return end
  mov.lastLiveWrite = agora
  recordFader(mov.element, value, ctx)
end

--- Fecha as linhas abertas. Chamado ao parar o play e ao desligar a
--  gravação: sem isso, o que estava aceso nunca chegaria a ser escrito.
function closeOpenLines()
  if not recorder or not session then return end
  if not Recorder.hasOpen(recorder) then return end

  -- Fecha na ÚLTIMA POSIÇÃO EM QUE ESTAVA TOCANDO, não na posição atual.
  --
  -- Ao dar stop, o REAPER devolve o cursor para onde o play começou.
  -- Usando a posição atual, o fim da nota caía ANTES do início dela e
  -- ela era encolhida ao tamanho mínimo — o sintoma era uma notinha
  -- curta no lugar de todo o trecho tocado.
  local ctx = context()
  local fim = ctx.qn
  if not ctx.playing and quadro.ultimaQN and quadro.ultimaQN > fim then
    fim = quadro.ultimaQN
  end

  local abertas = Recorder.openCount(recorder)
  local out = Recorder.closeAll(recorder, fim, session.byTag)
  if #out > 0 and Timeline.isReady() then
    Timeline.write(out)
    for _, it in ipairs(out) do
      log(('  fecha nota %-3s  %.3f -> %.3f QN'):format(
        tostring(it.pitch), it.startQN or 0, it.endQN or 0))
    end
  end
  log(('fechando %d linha(s) em %.2f QN (%s)')
    :format(abertas, fim, Transport.formatTime(Timeline.qnToTime(fim))))
end

--- Move o cursor, inclusive tocando ou GRAVANDO.
--
--  Parado ou tocando, é só mover o cursor.
--
--  GRAVANDO é que exige cuidado, e é a razão desta função existir. As
--  notas em curso crescem até a posição atual a cada quadro (ver
--  Recorder.growLive). Saltar sem mais nada esticaria cada nota aberta
--  por cima de todo o trecho pulado — um trecho em que você não estava
--  segurando botão nenhum. Pular pra trás faria pior: o fim cairia
--  antes do início e a nota encolheria ao tamanho mínimo, perdendo o
--  que já tinha sido gravado.
--
--  Então o salto é tratado como uma emenda: FECHA as linhas abertas na
--  posição de ANTES do salto (preservando o que foi tocado até ali) e
--  REABRE, na posição nova, as dos controles que continuam acesos. O
--  que estava aceso segue sendo gravado; o trecho pulado fica intacto.
--- Move o cursor AGORA, driblando o "smooth seek" do REAPER.
--
--  O PROBLEMA, diagnosticado no REAPER do usuário: clicar na onda
--  funcionava parado e não funcionava tocando. O registro mostrou o
--  salto sendo pedido com o destino certo e o cursor não saindo do
--  lugar — ou seja, o REAPER recebia e não aplicava. A causa estava em
--  `smoothseek=3` no reaper.ini: com o smooth seek ligado, um seek
--  durante a reprodução não acontece na hora, fica guardado para o fim
--  do compasso (ou do laço, conforme o valor). Numa música de quatro
--  minutos, isso se parece exatamente com "não funcionou".
--
--  A SAÍDA: desligar o smooth seek pelo tempo do salto e devolvê-lo em
--  seguida. A preferência do usuário continua valendo em todo o resto
--  do REAPER; só este salto é imediato — que é o que se pede ao clicar
--  num ponto da onda.
--
--  Depende do SWS (SNM_*ConfigVar), que é opcional: sem ele o salto é
--  feito do jeito normal e volta a obedecer o smooth seek, como antes.
local avisouSmoothSeek = false
local function seekImediato(segundos)
  local anterior = nil

  if Transport.isPlaying()
     and reaper.SNM_GetIntConfigVar and reaper.SNM_SetIntConfigVar then
    local valor = reaper.SNM_GetIntConfigVar('smoothseek', -1)
    if valor and valor > 0 then
      anterior = valor
      reaper.SNM_SetIntConfigVar('smoothseek', 0)
    end
  elseif Transport.isPlaying() and not reaper.SNM_GetIntConfigVar
         and not avisouSmoothSeek then
    avisouSmoothSeek = true
    log('sem a extensão SWS: se o cursor não saltar durante a reprodução, '
      .. 'desligue o "smooth seek" nas opções do REAPER')
  end

  Transport.setPosition(segundos, true)

  -- Devolvido SEMPRE, e já: deixar a preferência do usuário desligada
  -- por engano seria mudar o comportamento do REAPER inteiro dele.
  if anterior then
    reaper.SNM_SetIntConfigVar('smoothseek', anterior)
  end
end

--  DURANTE A GRAVAÇÃO, NÃO SALTA. A pedido, e com razão: mover o cursor
--  no meio de uma gravação mexe justamente no que está sendo escrito. As
--  notas em curso crescem até a posição atual a cada quadro (ver
--  Recorder.growLive), então um salto obriga a emendar — fechar onde
--  estava e reabrir no destino. Isso chegou a ser implementado e
--  funcionava, mas é máquina complicada a serviço de um gesto que, no
--  meio de uma gravação, quase sempre é engano. Recusar é mais seguro
--  que emendar bem.
--
--  @param segundos  destino
--  @param puxando  o mouse ainda está pressionado?
function saltarPara(segundos, puxando)
  if recording then return end

  saltoEmCurso = puxando and true or false
  seekImediato(segundos)

  if not puxando then
    -- DIAGNÓSTICO. Registra o pedido e o que o REAPER fez com ele.
    -- Foi o que permitiu descobrir que o "smooth seek" segurava o salto
    -- durante a reprodução: o destino saía certo aqui e o cursor não se
    -- mexia (ver seekImediato).
    log(('salto pedido para %s — cursor ficou em %s%s')
      :format(Transport.formatTime(segundos),
              Transport.formatTime(Transport.position()),
              Transport.isPlaying() and '  (tocando)' or '  (parado)'))
  end
end

function drawRecordBar()
  ImGui.Text(ctx, 'Track     ')
  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 230)
  local preview = Timeline.trackName or 'selecione a track de destino'
  if ImGui.BeginCombo(ctx, '##track', preview) then
    if #tracks == 0 then ImGui.Selectable(ctx, 'nenhuma track no projeto', false) end
    for _, t in ipairs(tracks) do
      if ImGui.Selectable(ctx, t.name, t.index == Timeline.trackIndex) then
        Timeline.setTrack(t.index, t.name)
        reaper.SetExtState(EXT_SECTION, EXT_TRACK, t.name, true)
      end
    end
    ImGui.EndCombo(ctx)
  end

  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Reler tracks') then refreshTracks() end
    dica('Relê a lista de tracks do projeto.')

  -- QUEBRA DE LINHA AQUI, de propósito.
  --
  -- Isto era uma fileira só: Track + combo + Reler + Substituir +
  -- Calibrar, quase 600px. Enquanto as configurações eram uma janela do
  -- sistema, larga, cabia; dentro do cartão não cabe, e o excesso era
  -- simplesmente cortado — sem barra de rolagem, sem aviso: o botão
  -- Calibrar sumia da tela. Duas linhas curtas cabem em qualquer
  -- largura que o cartão venha a ter.
  local chOv, ov = ImGui.Checkbox(ctx, 'Substituir', Timeline.overwrite)
    dica('Ao regravar, apaga as notas anteriores daquela altura e das rivais\ndo mesmo grupo, em vez de empilhar.')
  if chOv then Timeline.overwrite = ov end

  ImGui.SameLine(ctx)
  if calib then
    if ImGui.Button(ctx, 'Marcar tempo') then
      -- Mede contra a SEMÍNIMA, não contra a grade do projeto.
      --
      -- Você bate junto com a batida, não com o quadradinho. Se a grade
      -- estiver fina, a batida mais próxima na grade pode estar a menos
      -- de meio quadradinho do clique e a medida sairia menor que o
      -- atraso real: a 120 BPM, uma grade de 1/16 dura 125 ms, e um
      -- atraso de 200 ms seria medido como 75.
      local raw = Timeline.context(0)
      local beat = math.floor(raw.qn + 0.5)
      local delta = Timeline.qnToTime(raw.qn) - Timeline.qnToTime(beat)
      Calibration.tap(calib, delta)
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Aplicar') then
      if Calibration.ready(calib) then
        local median = Calibration.result(calib)
        if median then
          -- Negativo é legítimo: significa que você antecipa a batida.
          latency = median
          reaper.SetExtState(EXT_SECTION, EXT_OFFSET, tostring(latency), true)
        end
        calib = nil
      end
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Cancelar') then calib = nil end
  else
    if ImGui.Button(ctx, 'Calibrar') then
    dica('Mede o seu tempo de reação: dê play e marque o tempo junto\ncom a batida algumas vezes.') calib = Calibration.new() end
  end

  -- Diagnóstico do que está faltando. Antes, gravação ligada sem track
  -- (ou envio ligado sem porta) simplesmente não fazia nada, sem aviso.
  local faltando = {}
  if recording and not Timeline.isReady() then
    faltando[#faltando + 1] = 'nenhuma track selecionada'
  end
  if MidiOut.enabled and not MidiOut.isReady() then
    faltando[#faltando + 1] = 'nenhuma porta MIDI selecionada'
  end
  if not layout then faltando[#faltando + 1] = 'nenhuma tela personalizada carregada' end

  if #faltando > 0 then
    ImGui.TextColored(ctx, 0xFF8844FF,
      'Não vai funcionar: ' .. table.concat(faltando, '  ·  '))
  elseif calib then
    ImGui.TextColored(ctx, 0xFFCC55FF,
      'Calibração: dê play e clique em "Marcar tempo" junto com a batida.  '
      .. Calibration.describe(calib))
  elseif Timeline.lastError then
    ImGui.TextColored(ctx, 0xFF6666FF, Timeline.lastError)
  else
    ImGui.TextColored(ctx, 0x888888FF,
      ('%s  ·  gravadas: %d notas, %d CC  ·  substituídas: %d  ·  linhas abertas: %d')
        :format(recording and 'GRAVANDO' or 'parado',
                Timeline.notesWritten, Timeline.ccWritten,
                Timeline.notesRemoved or 0,
                recorder and Recorder.openCount(recorder) or 0))
  end
end

-- ------------------------------------------------------- atalhos

--- Monta a lista de atalhos a partir do .form.
--
--  A seção <keyboard> liga um código de tecla ao tag de um controle.
--  Nada é cadastrado aqui: trocar o .form troca os atalhos.
--
--  Montado sob demanda, no primeiro quadro após carregar, porque as
--  constantes de tecla do ImGui só podem ser lidas com o contexto pronto.
function buildShortcuts()
  shortcuts = {}
  if not layout then return end

  -- Inclui os controles cobertos. Escondê-los atrás de outro botão é
  -- justamente como se mantém uma função acessível só pelo teclado.
  local untranslated = 0
  formKeys = {}
  for _, sc in ipairs(Session.shortcuts(layout)) do
    formKeys[sc.code] = true
    local key = Compat.keyFromCode(ImGui, sc.code)
    if key then
      shortcuts[#shortcuts + 1] = {
        key = key, element = sc.element, code = sc.code, covered = sc.covered,
      }
    else
      untranslated = untranslated + 1
    end
  end

  -- F1-F12 definidas AQUI no LumiBridge (ver core/fkeys.lua), não no
  -- .form. Se o .form algum dia passar a usar uma tecla F também (hoje
  -- o próprio editor do Lumikit não permite), o .form manda: pula a
  -- atribuição do LumiBridge pra essa tecla, mesma regra do formKeys
  -- usada em pressedFree.
  local byTag = {}
  for _, el in ipairs(layout.elements) do
    if el.tag then byTag[el.tag] = el end
  end
  for code, tag in pairs(fkeyMap) do
    if not formKeys[code] then
      local el = byTag[tag]
      if el then
        local key = Compat.keyFromCode(ImGui, code)
        if key then
          shortcuts[#shortcuts + 1] = {
            key = key, element = el, code = code, covered = el.covered == true,
            source = 'lumibridge',
          }
        end
      end
    end
  end

  shortcuts.built = true

  -- Selo "F1".."F12" desenhado no canto do botão (ver
  -- ui/renderer.lua:drawButton). Reconstruído junto com os atalhos,
  -- que é sempre que fkeyMap muda.
  state.fkeyBadge = {}
  for code, tag in pairs(fkeyMap) do
    if not formKeys[code] then
      state.fkeyBadge[tag] = FKeys.label(code)
    end
  end

  local names = {}
  for _, sc in ipairs(shortcuts) do
    names[#names + 1] = ('%s=%s%s'):format(Compat.keyName(sc.code) or '?',
      sc.element.text ~= '' and sc.element.text or '(sem nome)',
      sc.covered and ' [oculto]' or '')
  end
  log(('%d atalho(s): %s%s')
    :format(#shortcuts, #names > 0 and table.concat(names, '  ') or 'nenhum',
            untranslated > 0
              and ('   (%d com código de tecla não suportado)'):format(untranslated)
              or ''))
end

--- Códigos de tecla usados pelo .form. Montado junto com os atalhos.
local formKeys = {}

-- Teclas de transporte esperando a SOLTURA para disparar. Ver aoSoltar.
local teclaPendente = {}
-- Estado da tecla no quadro anterior, só para o registro de diagnóstico.
local enterAntes = nil

--- Uma tecla foi pressionada E não pertence ao .form?
--
--  Esta é a única porta de entrada para atalhos do LumiBridge. As teclas
--  A–Z e F1–F12 pertencem ao usuário: é onde ele mapeia as funções do
--  Lumikit. Qualquer atalho nosso passa por aqui e desiste da tecla se
--  ela estiver mapeada no arquivo.
local function pressedFree(nomeTecla, codigoVirtual)
  local id = Compat.const(ImGui, nomeTecla, nil)
  if not id or id == 0 then return false end
  if codigoVirtual and formKeys[codigoVirtual] then return false end

  -- SEM REPETIÇÃO: por padrão o ImGui considera a tecla "pressionada" de
  -- novo enquanto ela fica segurada (auto-repeat), depois de um atraso
  -- inicial. Para um atalho de alternância (Espaço toca/para, Ctrl+R
  -- grava/para), isso pode disparar DUAS vezes num único toque um pouco
  -- mais longo — a ação liga e desliga de volta no mesmo gesto, e parece
  -- que a tecla "não funcionou". `false` aqui garante só uma borda de
  -- subida por toque.
  return ImGui.IsKeyPressed(ctx, id, false)
end

--- Dispara a ação QUANDO A TECLA É SOLTA, não quando é apertada.
--
--  POR QUE ISTO EXISTE — o defeito do Enter, que sobreviveu a três
--  tentativas de conserto:
--
--    O Enter tocava UMA vez e nunca mais. O registro provou que a
--    constante da tecla existe (Key_Enter = 525, o valor certo) e que a
--    primeira apertada era vista; da segunda em diante, nenhuma.
--
--    A explicação que sobra: as ações de transporte do REAPER puxam o
--    foco ENQUANTO A TECLA AINDA ESTÁ PRESSIONADA. Com o foco em outra
--    janela, o ImGui nunca recebe o evento de SOLTURA — e, para ele, a
--    tecla fica pressionada para sempre. Sem uma nova borda de descida,
--    IsKeyPressed nunca mais dispara. Não é a tecla que deixa de
--    chegar: é o estado dela que fica preso.
--
--    Agindo na soltura, o ImGui já viu a tecla subir ANTES de o foco
--    ir embora, e o estado não trava.
--
--  @param acao  recebe `ctrl`, o estado do Ctrl no momento da APERTADA
--               — na soltura ele já pode ter sido largado.
local function aoSoltar(nomeTecla, codigoVirtual, ctrlAgora, acao)
  local id = Compat.const(ImGui, nomeTecla, nil)
  if not id or id == 0 then return end
  if codigoVirtual and formKeys[codigoVirtual] then return end

  local segurada = false
  if ImGui.IsKeyDown then
    local ok, down = pcall(ImGui.IsKeyDown, ctx, id)
    segurada = ok and down or false
  end

  if segurada then
    if not teclaPendente[nomeTecla] then
      teclaPendente[nomeTecla] = { ctrl = ctrlAgora }
    end
  elseif teclaPendente[nomeTecla] then
    local pend = teclaPendente[nomeTecla]
    teclaPendente[nomeTecla] = nil
    acao(pend.ctrl)
  end
end

--- Grupos de fader por tecla numérica (1..9, depois 0): segurando a
--  tecla, a roda do mouse EM QUALQUER LUGAR da tela move junto todos os
--  faders do grupo — não precisa estar sobre nenhum fader específico.
--
--  Reaproveita a MESMA fila de deslize dos faders (Session.faderTarget,
--  avançada por Session.rampFaders a cada quadro): só decide o ALVO
--  aqui, igual à roda sobre um fader (ver Renderer.draw). O envio MIDI e
--  a gravação continuam saindo do laço do rampFaders, sem duplicar nada.
local function handleFaderGroups()
  if not session or not layout then return end

  local wheel = ImGui.GetMouseWheel(ctx)

  for _, num in ipairs(FaderGroups.NUMBERS) do
    local key = Compat.keyFromCode(ImGui, FaderGroups.CODES[num])
    local segurado = false
    if key then
      local ok, down = pcall(ImGui.IsKeyDown, ctx, key)
      segurado = ok and down or false
    end

    -- Ao soltar a tecla, esquece o alvo do modo "mesmo valor": o próximo
    -- aperto recomeça do valor que os faders tiverem NAQUELE momento, em
    -- vez de saltar pra um número de uma sessão de roda anterior.
    if groupWasHeld[num] and not segurado then
      groupSameTarget[num] = nil
    end
    groupWasHeld[num] = segurado
    groupHeldNow[num] = segurado

    if segurado and wheel and wheel ~= 0 then
      local grupo = faderGroups[num]
      if grupo and grupo.tags and #grupo.tags > 0 and grupo.ativo ~= false then
        local fine = state.shiftDown or false

        if grupo.mode == FaderGroups.MODE_SAME then
          if not groupSameTarget[num] then
            -- Começa do valor do primeiro fader do grupo: é o ponto de
            -- partida mais previsível quando eles ainda não estão iguais.
            local primeiro = session.byTag[grupo.tags[1]]
            groupSameTarget[num] =
              primeiro and Session.faderValue(session, primeiro) or 0
          end
          local passo = fine and Session.WHEEL_FINE or Session.WHEEL_STEP
          local alvo = groupSameTarget[num] + wheel * passo
          if alvo < 0 then alvo = 0 elseif alvo > 1 then alvo = 1 end
          groupSameTarget[num] = alvo

          for _, tag in ipairs(grupo.tags) do
            local el = session.byTag[tag]
            if el then
              Session.setFaderTarget(session, el, alvo)
              if recording then meus[tag] = true end
            end
          end
        else
          for _, tag in ipairs(grupo.tags) do
            local el = session.byTag[tag]
            if el then
              Session.wheelFader(session, el, wheel, fine)
              if recording then meus[tag] = true end
            end
          end
        end
      end
    end
  end
end

--- Processa os atalhos. Só age com a janela do LumiBridge em foco, para
--  não roubar teclas do REAPER quando você estiver editando o projeto.
--
--  SEM flags, IsWindowFocused só enxerga a janela PRINCIPAL: assim que o
--  clique cai dentro do canvas (que é um BeginChild, uma janela-filha do
--  ImGui), o foco passa a ser do filho e a chamada sem flags volta
--  false — os atalhos paravam de funcionar em qualquer clique num botão
--  ou área vazia da tela, só continuando após clicar na barra do topo.
--  ChildWindows faz IsWindowFocused contar o foco da janela principal OU
--  de qualquer uma das suas janelas-filhas.
local focoFlags = nil
local function handleShortcuts()
  if not focoFlags then
    focoFlags = Compat.windowFlags(ImGui, { 'FocusedFlags_ChildWindows' })
  end
  -- MUDANÇA de foco registrada, não o estado a cada quadro: uma linha
  -- por transição diz o que precisa ser dito sem afogar o registro. Foi
  -- a perda de foco logo após a primeira tecla que escondeu por muito
  -- tempo o defeito do Enter (ver devolverFoco).
  local focado = ImGui.IsWindowFocused(ctx, focoFlags)
  if focado ~= focoAnterior then
    focoAnterior = focado
    log(focado and 'foco: recuperado' or 'foco: perdido (atalhos em pausa)')
  end
  if not focado then
    -- SEM FOCO, NENHUMA TECLA ESTÁ SEGURADA.
    --
    -- `groupHeldNow` é escrito por handleFaderGroups, que não roda sem
    -- foco — então ele ficava preso no último valor. Segurar a tecla de
    -- um grupo e clicar fora deixava o grupo "segurado" para sempre: o
    -- arrasto seguinte de qualquer fader do grupo levava os companheiros
    -- junto sem ninguém ter pedido, e não havia como desfazer isso a não
    -- ser apertando e soltando a tecla de novo.
    for _, num in ipairs(FaderGroups.NUMBERS) do
      groupHeldNow[num] = false
      groupWasHeld[num] = false
      groupSameTarget[num] = nil
    end
    return
  end

  -- ESPAÇO toca e pausa, como no REAPER. Fica fora da checagem de
  -- `opcoes.atalhos` porque não vem do .form: é transporte, não função de
  -- iluminação.
  --
  -- WantCaptureKeyboard é verdadeiro quando um campo de texto está em
  -- edição; sem essa guarda, digitar um espaço num campo dispararia o
  -- play.
  if not shortcuts.built and layout then buildShortcuts() end

  local digitando = false

  -- Detecta se um campo de texto está capturando o teclado.
  --
  -- SEMPRE via Compat.get: o shim do ReaImGui LANÇA ERRO ao acessar um
  -- campo que não existe, em vez de devolver nil. Testar com
  -- `if ImGui.GetIO then` é justamente o que derruba o script — a
  -- própria verificação de existência causa a falha.
  --
  -- A partir da 0.9 o acesso ao IO é por funções nomeadas; GetIO não
  -- existe mais. Tentamos as duas formas conhecidas e, se nenhuma
  -- existir, seguimos sem a guarda: o pior caso é um espaço digitado
  -- num campo disparar o play, o que é reversível.
  -- USA A MARCA DOS PRÓPRIOS CAMPOS, não IsAnyItemActive.
  --
  -- IsAnyItemActive é verdadeiro para QUALQUER item ativo — um botão
  -- sendo segurado, um combo aberto, um item que ganhou foco de teclado
  -- — e não só para um campo de texto em edição. Com ele, qualquer
  -- desses estados calava TODOS os atalhos, e o sintoma era o relatado:
  -- o Enter (que pausa) funcionava uma vez e depois parava, porque a
  -- própria tecla deixava um item ativo do lado do ImGui.
  --
  -- Campos de texto no LumiBridge são só dois (a busca de músicas e a
  -- de faders), e cada um se marca ao ser desenhado. É uma condição
  -- estreita e verdadeira, em vez de uma ampla e aproximada.
  digitando = campoTextoAtivo

  -- Ctrl pressionado? Todo atalho do LumiBridge usa modificador, para
  -- não disputar teclas com os mapeamentos do .form.
  --
  -- Checagem pelas teclas FÍSICAS (Key_LeftCtrl / Key_RightCtrl), não
  -- pela flag de modificador (Mod_Ctrl): a flag nem sempre é aceita por
  -- IsKeyDown, dependendo da geração do ReaImGui instalada — e falhando
  -- em silêncio (pcall -> false), Ctrl+Espaço caía sempre no ramo de
  -- Espaço sozinho (tocar/parar) em vez de pausar.
  local ctrlDown = false
  if ImGui.IsKeyDown then
    local left  = Compat.const(ImGui, 'Key_LeftCtrl', nil)
    local right = Compat.const(ImGui, 'Key_RightCtrl', nil)
    if left and left ~= 0 then
      local okL, down = pcall(ImGui.IsKeyDown, ctx, left)
      if okL and down then ctrlDown = true end
    end
    if right and right ~= 0 then
      local okR, down = pcall(ImGui.IsKeyDown, ctx, right)
      if okR and down then ctrlDown = true end
    end
  end

  -- TECLADO NUMÉRICO: +, - e . comandam as faixas.
  --
  -- O + MOSTRA e o - ESCONDE, em vez de os dois alternarem: apertando o
  -- + você sabe o que vai acontecer sem precisar lembrar do estado atual
  -- — que é o ponto de ter duas teclas em vez de uma.
  --
  -- O numérico está livre pela regra da casa: A-Z, 0-9 e Espaço são do
  -- .form, F1-F12 são do LumiBridge, e estas três não disputam com nada.
  if not digitando then
    --- Alguma destas teclas foi apertada neste quadro?
    --
    --  UMA LISTA, e não um nome só, porque nem toda geração do ReaImGui
    --  expõe as mesmas constantes — e uma que falta some em silêncio:
    --  Compat.const devolve 0, o `if` não entra, e a tecla simplesmente
    --  não faz nada. Foi o que aconteceu com o ponto do numérico.
    --
    --  O ponto aceita também o ponto do teclado normal. Com o NumLock
    --  DESLIGADO o ponto do numérico deixa de ser "decimal" e vira
    --  Delete — nada que um script possa contornar —, então ter uma
    --  segunda tecla para a mesma função é o que garante o comando.
    local function tecla(...)
      if not ImGui.IsKeyPressed then return false end
      for _, nome in ipairs({ ... }) do
        local k = Compat.const(ImGui, nome, nil)
        if k and k ~= 0 then
          local ok, v = pcall(ImGui.IsKeyPressed, ctx, k, false)
          if ok and v == true then return true end
        end
      end
      return false
    end

    --- O CARACTERE foi digitado neste quadro?
    --
    --  Caminho alternativo, que não depende de nome de constante nenhum.
    --  O ponto do numérico não funcionava e as duas causas possíveis são
    --  invisíveis daqui: ou aquela geração do ReaImGui não expõe
    --  Key_KeypadDecimal (e Compat.const devolve 0, o teste não entra e a
    --  tecla morre em silêncio), ou o NumLock está desligado e o sistema
    --  manda outra tecla. A fila de caracteres contorna as duas: o que
    --  chega ali é o que foi DIGITADO, não o nome que alguém deu à tecla.
    local function caractere(codigo)
      local ler = Compat.get(ImGui, 'GetInputQueueCharacter')
      if not ler then return false end
      for i = 0, 15 do
        local ok, temMais, c = pcall(ler, ctx, i)
        if not ok or not temMais then return false end
        if c == codigo then return true end
      end
      return false
    end

    local function numerico(...)
      return tecla(...)
    end

    if (numerico('Key_KeypadAdd') or caractere(43))
       and not faixas.abertas then
      faixas.abertas = true
      faixas.at, faixas.ajustar = 0, true
      encaixe.w = 0
      log('Programação MIDI: aberta (+ do numérico)')
    end

    if (numerico('Key_KeypadSubtract') or caractere(45))
       and faixas.abertas then
      faixas.abertas = false
      faixas.sel = nil
      encaixe.w = 0
      log('Programação MIDI: fechada (- do numérico)')
    end

    -- DIAGNÓSTICO, uma vez só: quais destas constantes esta instalação
    -- do ReaImGui realmente tem. Uma tecla que não faz nada e não diz
    -- por quê é o pior tipo de defeito para acertar à distância.
    if painel.verbose and not faixas.teclasDitas then
      faixas.teclasDitas = true
      local achadas = {}
      for _, nome in ipairs({ 'Key_KeypadAdd', 'Key_KeypadSubtract',
                              'Key_KeypadDecimal', 'Key_Period',
                              'Key_Equal', 'Key_Minus' }) do
        local k = Compat.const(ImGui, nome, nil)
        achadas[#achadas + 1] = ('%s=%s'):format(nome,
          (k and k ~= 0) and tostring(k) or 'AUSENTE')
      end
      log('teclas do numérico: ' .. table.concat(achadas, '  '))
    end

    -- * DO NUMÉRICO: esconde e mostra o painel do .form.
    --
    -- É o mesmo estado do botão "inteira" no cabeçalho das faixas: com o
    -- painel escondido, as faixas ocupam a janela toda. Ter tecla para
    -- isso é o que torna suportável trabalhar num monitor só — alterna
    -- entre editar a programação e apertar os botões sem tirar a mão do
    -- teclado.
    if numerico('Key_KeypadMultiply') or caractere(42) then
      if not faixas.abertas then
        faixas.abertas = true
        faixas.ajustar = true
      end
      faixas.inteira = not faixas.inteira
      faixas.at, encaixe.w = 0, 0
      log(('Tela Personalizada: %s (* do numérico)')
        :format(faixas.inteira and 'escondido' or 'visível'))
    end

    if numerico('Key_KeypadDecimal', 'Key_Period') or caractere(46) then
      faixas.semCC = not faixas.semCC
      faixas.at = 0
      local ok = CCLanes.toggle()
      log(('CC %s (. do numérico)%s'):format(
        faixas.semCC and 'ocultos' or 'visíveis',
        ok and '' or ' — o editor MIDI não acompanhou'))
    end
  end

  -- CTRL+J JUNTA o bloco selecionado com o seguinte do mesmo controle.
  --
  -- J de join, e com Ctrl porque a regra da casa reserva as letras soltas
  -- ao .form. A guarda é a seleção: sem bloco escolhido, não faz nada.
  if not digitando and faixas.sel and faixas.abertas and ctrlDown then
    local teclaJ = Compat.const(ImGui, 'Key_J', nil)
    if teclaJ and teclaJ ~= 0 and ImGui.IsKeyPressed then
      local ok, apertouJ = pcall(ImGui.IsKeyPressed, ctx, teclaJ, false)
      if ok and apertouJ then
        for _, l in ipairs(faixas.linhas) do
          if l.tag == faixas.sel.tag then
            for _, b in ipairs(l.blocos) do
              if math.abs(b.t0 - faixas.sel.t0) < 0.002 then
                juntarBlocos(l, b)
              end
            end
          end
        end
      end
    end
  end

  -- DEL APAGA O BLOCO SELECIONADO nas faixas de programação.
  --
  -- SEM MODIFICADOR, o que contraria a regra geral dos atalhos daqui —
  -- mas Del não é uma tecla que o .form possa reivindicar (só letras,
  -- números e espaço são), e apagar com Del é o gesto que qualquer
  -- editor tem. A guarda é a seleção: sem bloco escolhido, a tecla não
  -- faz nada.
  if not digitando and faixas.sel and faixas.abertas then
    local teclaDel = Compat.const(ImGui, 'Key_Delete', nil)
    if teclaDel and teclaDel ~= 0 and ImGui.IsKeyPressed then
      local ok, apertou = pcall(ImGui.IsKeyPressed, ctx, teclaDel, false)
      if ok and apertou then
        local foi

        Timeline.editar('LumiBridge: apagar nota', function()
        -- O desligamento acompanha, como no duplo clique.
        if faixas.sel.fecho then
          Timeline.deleteNoteAt(faixas.sel.pitch, faixas.sel.fecho.t0)
        end
        foi = Timeline.deleteNoteAt(faixas.sel.pitch, faixas.sel.t0)
        end)
        log(foi and ('apagado: %s em %s'):format(
              tostring(faixas.sel.nome or faixas.sel.pitch),
              Transport.formatTime(faixas.sel.t0))
            or 'nada apagado: a nota não está mais onde estava')
        faixas.sel = nil
        faixas.at = 0
      end
    end
  end

  if not digitando then
    -- Espaço toca e para; Ctrl+Espaço pausa. Se o .form usar ESPAÇO para
    -- algum botão, o .form manda e o transporte abre mão dele.
    -- SHIFT+ESPAÇO TAMBÉM PAUSA.
    --
    -- Existe porque o Enter pode NÃO CHEGAR até aqui, e isso não tem
    -- conserto do lado do script: uma extensão do REAPER que instale um
    -- GANCHO DE TECLADO recebe a tecla antes de qualquer janela, e um
    -- ReaScript não tem como ter prioridade sobre ela. Na máquina onde
    -- isto foi investigado era a reaper_VSHookExt.dll, que usa o Enter
    -- para gerenciar as músicas.
    --
    -- Foi um bom tempo de investigação até aparecer a pergunta que
    -- matou as teorias todas: "como pode o Ctrl+Espaço funcionar?".
    -- Foco perdido e estado de tecla preso teriam derrubado os dois
    -- atalhos; só uma captura ESPECÍFICA do Enter explica um funcionar
    -- e o outro não.
    --
    -- O Enter continua mapeado de propósito: onde não há gancho
    -- disputando, ele funciona. Shift+Espaço é a porta que não depende
    -- disso, para quem tenha o Ctrl+Espaço tomado por outro programa.
    local pausar = ctrlDown or (state.shiftDown or false)
    aoSoltar('Key_Space', 32, pausar, function(comModificador)
      if comModificador then
        Transport.togglePlayPause()
      else
        Transport.togglePlayStop()
      end
      -- A ação do REAPER leva o foco junto; devolve, senão o atalho
      -- seguinte não é mais visto. Ver devolverFoco.
      devolverFoco()
    end)

    -- ENTER também pausa — atalho alternativo, sem modificador.
    --
    -- Exceção deliberada à regra "todo atalho do LumiBridge usa
    -- modificador": em alguns sistemas Ctrl+Espaço é capturado por
    -- outro programa (ex.: o Claude desktop usa Ctrl+Espaço como
    -- atalho global) antes de chegar ao REAPER. Enter é seguro aqui
    -- porque não é uma tecla que o .form saiba mapear
    -- (Compat.keyFromCode só traduz A-Z, 0-9, F1-F12 e Espaço), então
    -- não disputa com nenhum botão do Lumikit — e `pressedFree` ainda
    -- cede a tecla se o .form vier a usar o código 13 por algum motivo.
    --
    -- USA togglePlayPause() (ação nativa 40073), NÃO pause() (1008):
    -- 1008 só PAUSA, não retoma — apertar de novo enquanto já pausado
    -- não fazia nada. 40073 é o mesmo "Play/pause" que o Ctrl+Espaço
    -- do próprio REAPER usa, e alterna corretamente nos dois sentidos.
    -- Os DOIS Enter: o do teclado principal e o do numérico. Em algumas
    -- versões do ReaImGui são teclas distintas, e quem usa o numérico
    -- ficava sem o atalho sem entender por quê.
    -- DIAGNÓSTICO: o estado da tecla, registrado só quando MUDA.
    --
    -- É a prova direta da explicação em aoSoltar. Se, depois da
    -- primeira apertada, aparecer "Enter pressionado" e nunca
    -- "Enter solto", o estado ficou preso do lado do ImGui — e é por
    -- isso que nenhuma apertada seguinte é vista.
    do
      local id = Compat.const(ImGui, 'Key_Enter', nil)
      if id and id ~= 0 and ImGui.IsKeyDown then
        local ok, down = pcall(ImGui.IsKeyDown, ctx, id)
        down = ok and down or false
        if down ~= enterAntes then
          enterAntes = down
          log(down and 'Enter pressionado' or 'Enter solto')
        end
      end
    end

    local function playPausa()
      local antes = Transport.isPlaying() and 'tocando'
        or (Transport.isPaused() and 'pausado' or 'parado')
      Transport.togglePlayPause()
      log(('Enter: play/pausa  (%s -> %s)'):format(antes,
        Transport.isPlaying() and 'tocando'
        or (Transport.isPaused() and 'pausado' or 'parado')))
      devolverFoco()
    end

    -- Os DOIS Enter: o do teclado principal e o do numérico. Em algumas
    -- versões do ReaImGui são teclas distintas, e quem usa o numérico
    -- ficava sem o atalho sem entender por quê.
    aoSoltar('Key_Enter', 13, false, playPausa)
    aoSoltar('Key_KeypadEnter', 13, false, playPausa)

    -- Ctrl+R grava, como no REAPER.
    --
    -- As teclas de A a Z e F1 a F12 são RESERVADAS ao .form: é ali que
    -- o usuário mapeia as funções do Lumikit. Um atalho do LumiBridge
    -- sem modificador roubaria uma tecla de trabalho, e isso vale para
    -- qualquer atalho que venhamos a acrescentar.
    -- Ctrl+Z desfaz, Ctrl+Shift+Z refaz. Com a janela do LumiBridge em
    -- foco o REAPER não recebe as teclas, então repassamos.
    if ctrlDown and pressedFree('Key_Z', 90) then
      local shift = false
      local modShift = Compat.const(ImGui, 'Mod_Shift', nil)
      if modShift and modShift ~= 0 and ImGui.IsKeyDown then
        local okS, down = pcall(ImGui.IsKeyDown, ctx, modShift)
        shift = okS and down or false
      end
      desfazerOuRefazer(shift)
    end

    -- ESC FECHA AS CONFIGURAÇÕES. É o que qualquer janela sobreposta
    -- faz, e aqui não disputa com nada: sem elas abertas, Esc não tem
    -- outro dono nesta interface.
    if painel.aberto and pressedFree('Key_Escape', 27) then
      painel.aberto = false
    end

    if ctrlDown and pressedFree('Key_R', 82) then
      if recording then stopRecording() else startRecording() end
    end

    -- AO COMEÇO DA MÚSICA, na seta esquerda. Voltar ao início é o gesto
    -- mais repetido de quem programa — ouve o trecho, ajusta, volta,
    -- ouve de novo —, e uma tecla só é melhor que um acorde para algo
    -- feito dezenas de vezes por música.
    --
    -- SEM Ctrl, ao contrário dos outros atalhos daqui: as setas não
    -- disputam com os mapeamentos do .form, que usam letras, números e
    -- espaço.
    if not ctrlDown and pressedFree('Key_LeftArrow', 37) and region then
      saltarPara(region.startTime, false)
    end

    -- Grupos de fader (1..9, 0): não depende do .form nem do interruptor
    -- "Atalhos" — é um gesto de mouse (roda) guiado por uma tecla, mais
    -- perto do arrasto de fader do que de um atalho de clique.
    handleFaderGroups()
  end

  if not opcoes.atalhos or not session then return end

  -- COM CTRL SEGURADO, AS TECLAS DA TELA NÃO VALEM.
  --
  -- Todo atalho do LumiBridge usa Ctrl justamente para não disputar
  -- teclas com os mapeamentos da Tela Personalizada — mas o lado da TELA
  -- nunca conferiu isso. O resultado é que cada Ctrl+letra disparava as
  -- DUAS coisas.
  --
  -- Nesta tela, R é o RELEASE ALL: Ctrl+R ligava a gravação E mandava o
  -- release. E Z é um controle sem nome: Ctrl+Z desfazia E o acionava.
  -- Foi o que apareceu no registro do usuário — "tecla Z -> (sem nome)"
  -- logo depois de um Ctrl+Z — e é a explicação de uma gravação inteira
  -- desaparecer depois de desfazer o movimento de um ponto.
  --
  -- Uma tecla com modificador é OUTRA tecla. Quem programou "Z" na Tela
  -- programou Z, não Ctrl+Z.
  if ctrlDown then return end

  if not shortcuts.built then buildShortcuts() end

  for _, sc in ipairs(shortcuts) do
    local e = sc.element
    local intents

    if e.momentary then
      -- Momentâneo segue a tecla: age enquanto estiver pressionada.
      --
      -- A MARCA É DO TECLADO, não do Session — e essa era a falha.
      --
      -- `session.holding` é escrito por Session.hold, que o MOUSE também
      -- chama: o botão do .form e, agora, o nome na lista de faixas.
      -- Lendo essa marca aqui, o teclado via "estava segurado, e a
      -- minha tecla não está apertada" no quadro seguinte a qualquer
      -- aperto de mouse — e SOLTAVA o que a mão ainda segurava, sem
      -- passar pelo laço de eventos. Segurar o FUMAÇA com o mouse
      -- acendia e apagava num quadro: um ponto só no MIDI.
      --
      -- Vale para os dois caminhos do mouse, não só para a lista: o
      -- botão do .form tinha o mesmo defeito, e só não aparecia porque
      -- os momentâneos com tecla costumam ser acionados PELA tecla.
      --
      -- Cada origem do gesto guarda a sua marca: o .form tem
      -- state.holding, a lista tem faixas.segurando, e o teclado tem
      -- esta. Uma marca compartilhada é uma marca de ninguém.
      local down = ImGui.IsKeyDown(ctx, sc.key)
      local was  = teclaSegura[e.tag] or false
      if down and not was then
        intents = Session.hold(session, e)
      elseif was and not down then
        intents = Session.release(session, e)
      end
      teclaSegura[e.tag] = down
    elseif ImGui.IsKeyPressed(ctx, sc.key) then
      intents = Session.press(session, e)
    end

    if intents then
      for _, intent in ipairs(intents) do
        if intent.action == 'send' then
          MidiOut.sendAll(intent.commands, intent.value)
        elseif intent.action == 'release' then
          MidiOut.releaseAll(intent.commands)
        end
      end

      -- GRAVAÇÃO. Faltava aqui: o clique do mouse já grava (ver o laço
      -- de eventos mais abaixo, em torno de `record(intents, rctx)`),
      -- mas o atalho de teclado só mandava o MIDI e nunca chamava essa
      -- função — qualquer controle acionado só pelo teclado ficava de
      -- fora da gravação, mesmo com REC ligado. Mesma função, mesmas
      -- `intents` já calculadas acima; nenhuma lógica nova.
      if recording and recorder and Timeline.isReady() then
        record(intents, context())
      end
      -- Passa a ser SEU até o fim da gravação, igual ao clique do mouse.
      if recording and e.tag then meus[e.tag] = true end

      log(('tecla %-3s -> %s')
        :format(Compat.keyName(sc.code) or '?', e.text ~= '' and e.text or '(sem nome)'))
    end
  end
end

--- Revalida porta MIDI e track de tempos em tempos.
--
--  Trocar de projeto, renomear a track ou mexer nas portas do sistema
--  invalidava a seleção EM SILÊNCIO: a gravação simplesmente parava e
--  não havia nada na tela dizendo por quê. Aqui a seleção é reencontrada
--  pelo NOME, que é estável, e o que não for encontrado vira aviso.
local function recheckBindings()
  local now = reaper.time_precise and reaper.time_precise() or 0
  if now < quadro.recheckAt then return end

  -- Espaçamento maior num projeto grande: reler e ordenar centenas de
  -- regiões é caro, e elas não mudam de dois em dois segundos.
  quadro.recheckAt = now + (#regions > 100 and 10.0 or 2.0)

  -- No modo "pela track", mantém a track pronta: armada, com entrada de
  -- teclado virtual e monitoração ligada.
  --
  -- Refeito aqui porque esses ajustes se perdem ao trocar de projeto ou
  -- se a track for desarmada sem querer — e a falha é silenciosa: o
  -- MIDI simplesmente para de sair, sem erro nenhum.
  if MidiOut.route == 'track' and Timeline.isReady() then
    Timeline.armForVirtualKeyboard()
  end

  regions = Transport.regions()

  -- Cópia em ordem ALFABÉTICA para a lista de escolha. A ordem por
  -- tempo continua valendo para os saltos de "anterior" e "próxima",
  -- que seguem a linha do tempo.
  regioesOrdenadas = {}
  for _, rg in ipairs(regions) do
    if rg.isRegion then regioesOrdenadas[#regioesOrdenadas + 1] = rg end
  end
  table.sort(regioesOrdenadas, function(a, b)
    return a.name:upper() < b.name:upper()
  end)

  -- A REGIÃO NÃO MUDA SOZINHA.
  --
  -- Antes ela seguia o cursor: mover o playhead para fora da música
  -- trocava a região de trabalho no meio da programação. Agora a
  -- escolha só muda quando o usuário escolhe outra na lista — ou
  -- quando ainda não há nenhuma.
  -- A ESCOLHA DA MÚSICA É SUA, E SÓ SUA.
  --
  -- Uma vez escolhida, a região NUNCA troca sozinha — nem pelo cursor,
  -- nem por uma seleção de tempo feita no REAPER. Havia uma exceção
  -- deliberada aqui: uma seleção de tempo batendo com outra região do
  -- projeto trocava a música em uso, pensada como "atalho alternativo"
  -- de escolha. Na prática, qualquer seleção de tempo no REAPER (feita
  -- por outro motivo qualquer, nada a ver com trocar de música) também
  -- disparava a troca — com o LumiBridge aberto, uma seleção assim é
  -- sempre um acidente, então essa exceção foi removida: com a janela
  -- aberta, só a lista do próprio LumiBridge escolhe a música.
  if region then
    -- Reencontra a MESMA região pela posição, para acompanhar edições
    -- de limite. Não achou? Mantém a que está: melhor uma referência
    -- antiga do que pular para outra música.
    for _, rg in ipairs(regions) do
      if rg.isRegion and math.abs(rg.startTime - region.startTime) < 0.5 then
        region = rg
        break
      end
    end
  elseif not regionPinned then
    -- Primeira vez, sem nada escolhido: adota a que estiver sob o cursor.
    region = Transport.currentRegion(regions)
  end

  -- A grade do projeto pode ser mudada a qualquer momento pelo usuário.
  if recorder then Recorder.setGrid(recorder, Timeline.projectGrid()) end

  refreshTracks()
  if Timeline.trackName then
    local found = Timeline.findTrackByName(Timeline.trackName)
    if found then
      Timeline.setTrack(found.index, found.name)
    else
      Timeline.trackIndex = nil
    end
  end

  if MidiOut.deviceName and MidiOut.deviceIndex == nil then
    refreshDevices()
    local dev = MidiOut.findDeviceByName(MidiOut.deviceName)
    if dev then MidiOut.setDevice(dev.index, dev.name) end
  end
end

--- Configurações — um CARTÃO centralizado por cima da janela principal.
--
--  HISTÓRICO, para não repetir os dois formatos já descartados:
--
--    até a V102  janela separada do sistema operacional. Duas janelas
--                para uma coisa só confundia, e fechar a de ajustes sem
--                querer somava à dúvida de "isso fechou tudo ou ficou
--                rodando escondido?".
--
--    V103..V107  gaveta colada à direita, ocupando metade da largura.
--                Cortava conteúdo, e não por pouco: a fileira do Destino
--                (Track + combo + Reler + Substituir + Calibrar) pede uns
--                600px, e a área de conteúdo da gaveta tinha 480. Alargar
--                a gaveta só empurrava o problema.
--
--  Agora é um cartão no meio, com o layout escurecido atrás. Duas coisas
--  fazem o corte não voltar: o cartão cresce com a janela em vez de ficar
--  preso a uma fração dela, e as fileiras compridas foram quebradas em
--  linhas (ver drawRecordBar).
--
--  A ORDEM DE DESENHO IMPORTA. São três camadas, submetidas nesta ordem,
--  porque no ImGui quem vem depois fica por cima — tanto no desenho
--  quanto no teste do mouse:
--
--    1. o véu, um filho do tamanho da área útil. Escurece o layout E
--       engole os cliques que não forem no cartão: sem ele, clicar "fora"
--       acionaria um botão do .form atrás. Clicar nele fecha.
--    2. o cartão.
--    3. a moldura do cartão, direto no DrawList da janela.
--
--  O véu precisa ser um FILHO, e não um InvisibleButton solto na janela:
--  o canvas também é um filho, e um item da janela-mãe nunca ganha o
--  mouse de um filho que esteja embaixo do cursor.
--
--  @param x, y            canto superior esquerdo da área útil da
--                          janela, capturado logo após a barra de
--                          ferramentas (ANTES do canvas — precisa ser
--                          de onde o canvas COMEÇARIA, não de onde ele
--                          deixou o cursor depois de desenhado)
--  @param availW, availH  tamanho dessa mesma área útil
local function drawSettingsPanel(x, y, availW, availH)
  if not painel.aberto then return end
  if not x or not availW or availW <= 0 then return end
  if not availH or availH <= 0 then return end

  local fechar = false

  -- ------------------------------------------------------------ 1) véu
  -- Opacidade bem alta de propósito: numa primeira tentativa (alpha C0,
  -- 75%) o layout atrás continuava lendo-se claramente e competia com
  -- as Configurações pela atenção — quase opaco é o que de fato lê como
  -- "esfumado" contra o fundo já escuro da moldura do LumiBridge.
  local nVeu = empilhaFundo(0x0A0B0DF5)
  ImGui.SetCursorScreenPos(ctx, x, y)
  if ImGui.BeginChild(ctx, '##configVeu', availW, availH) then
    -- Descontado o espaçamento interno do filho dos dois lados, senão a
    -- área clicável passa do tamanho do véu e ele ganha barra de rolagem.
    ImGui.InvisibleButton(ctx, '##foraDoCartao',
                          math.max(1, availW - 18), math.max(1, availH - 14))
    if ImGui.IsItemClicked(ctx) then fechar = true end
    ImGui.EndChild(ctx)
  end
  if nVeu > 0 then pcall(ImGui.PopStyleColor, ctx, 1) end

  -- --------------------------------------------------------- 2) cartão
  -- Cresce com a janela, entre um mínimo legível e um teto que evita
  -- uma caixa de ajustes gigante numa tela grande.
  local largura = math.floor(math.max(520, math.min(900, availW - 60)))
  local altura  = math.floor(math.max(340, math.min(640, availH - 50)))
  if largura > availW then largura = availW end
  if altura  > availH then altura  = availH end

  -- Arredondado: coordenada fracionária faz a moldura horizontal e a
  -- vertical caírem em sub-pixels diferentes e a suavização do ImGui
  -- as trata de jeitos diferentes — uma borda claramente mais grossa
  -- que a outra, mesmo sendo o mesmo 1px pedido nos dois lados.
  local px = math.floor(x + (availW - largura) * 0.5)
  local py = math.floor(y + (availH - altura) * 0.5)

  -- -------------------------------------------------------- 2b) moldura
  -- DrawList_AddRect não estava aparecendo nesta versão do ReaImGui —
  -- nem grossa, nem clara, nem opaca — apesar de funcionar em teoria.
  -- Como o separador embaixo do título (ImGui.Separator, mais abaixo)
  -- É visível de verdade, a moldura passa a usar a MESMA técnica: um
  -- child com ChildBg preenchido, igual véu e cartão. Desenhada ANTES
  -- do cartão, do tamanho cheio; o cartão vem por cima encolhido por
  -- BORDA de cada lado, e só a faixa clara ao redor fica à mostra —
  -- geometria garantida, sem depender de nenhuma chamada de desenho
  -- cujo comportamento eu não consigo verificar sem o REAPER aberto.
  -- A MESMA cor do Separator (Theme.push empurra 'Col_Separator' com
  -- este valor) — pedido explicitamente como referência. O branco
  -- suave da tentativa anterior ainda lia como contorno chapado; esta
  -- é literalmente a cor que a linha embaixo do título já usa.
  local BORDA = 1
  local nBorda = empilhaFundo(0x2A2F3AFF)
  ImGui.SetCursorScreenPos(ctx, px, py)
  if ImGui.BeginChild(ctx, '##configMoldura', largura, altura) then
    ImGui.EndChild(ctx)
  end
  if nBorda > 0 then pcall(ImGui.PopStyleColor, ctx, 1) end

  -- --------------------------------------------------------- 3) cartão
  local pxCartao = px + BORDA
  local pyCartao = py + BORDA
  local larguraCartao = largura - 2 * BORDA
  local alturaCartao  = altura  - 2 * BORDA

  -- Respiro interno do cartão: sem isso o texto ficava colado nas
  -- bordas e as duas colunas (abas/conteúdo) quase se tocavam.
  --
  -- Tentativa anterior empurrava StyleVar_WindowPadding antes do
  -- BeginChild, pra valer nos filhos aninhados por herança de estilo.
  -- Não pegou nesta versão do ReaImGui — o conteúdo continuou colado
  -- nas quatro bordas. Troca por um recuo GEOMÉTRICO: um child interno
  -- menor que o cartão, deslocado pra dentro por MARGEM em todo lado.
  -- Isso não depende de nenhum style var propagar — é aritmética de
  -- posição e tamanho, o mesmo tipo de cálculo que já posiciona véu,
  -- cartão e moldura logo acima.
  local MARGEM = 16
  local nCartao = empilhaFundo(Theme.UI.bg)
  ImGui.SetCursorScreenPos(ctx, pxCartao, pyCartao)
  if ImGui.BeginChild(ctx, '##configCartao', larguraCartao, alturaCartao) then
    ImGui.SetCursorPos(ctx, MARGEM, MARGEM)
    if ImGui.BeginChild(ctx, '##configCartaoConteudo',
                        larguraCartao - 2 * MARGEM, alturaCartao - 2 * MARGEM) then
      local larguraConteudo = ImGui.GetContentRegionAvail(ctx)

      -- LINHA DE CABEÇALHO com altura PRÓPRIA (26px), e título e × os
      -- dois centrados DENTRO dela.
      --
      -- A tentativa anterior centrava o botão de 22px sobre o texto de
      -- 13px, o que jogava o topo do botão ~4px ACIMA do começo da área
      -- do cartão — e ali ele era cortado pelo recorte do filho. Uma
      -- linha com altura própria resolve os dois de uma vez: nada sobe
      -- além do topo, e os dois compartilham o mesmo centro vertical.
      local CAB_H, X_W = 26, 26
      local cabX, cabY = ImGui.GetCursorScreenPos(ctx)
      cabX, cabY = math.floor(cabX), math.floor(cabY)
      local _, alturaTitulo = ImGui.CalcTextSize(ctx, 'Configurações')

      ImGui.SetCursorScreenPos(ctx, cabX,
        math.floor(cabY + (CAB_H - alturaTitulo) * 0.5))
      ImGui.Text(ctx, 'Configurações')

      -- O ASSISTENTE NO TOPO, e não escondido numa aba: quem precisa
      -- dele é justamente quem ainda não sabe que existem abas.
      do
        local larguraTitulo = ImGui.CalcTextSize(ctx, 'Configurações')
        ImGui.SetCursorScreenPos(ctx,
          math.floor(cabX + larguraTitulo + 18), cabY + 1)
        if ImGui.Button(ctx, 'Assistente', 96, 24) then
          painel.assist.aberto = true
          painel.assist.passo  = 1
          painel.assist.recado = nil
          refreshDevices()
          refreshTracks()
        end
        dica('Refaz os primeiros ajustes, um por tela: a Tela\n'
          .. 'Personalizada, a porta MIDI, a track de gravação e a\n'
          .. 'track de referência da onda.')
      end

      -- O MESMO × da barra de título, e não um botão escrito "Fechar":
      -- duas formas diferentes de fechar coisas, na mesma tela, eram
      -- ruído — fechar é fechar.
      do
        -- 2px de folga da borda direita: encostado, o arredondamento do
        -- fundo vermelho ficava rente demais ao limite do cartão.
        local bx = math.floor(cabX + larguraConteudo - X_W - 2)

        ImGui.SetCursorScreenPos(ctx, bx, cabY)
        ImGui.InvisibleButton(ctx, '##fecharConfig', X_W, CAB_H)
        local sobre = ImGui.IsItemHovered(ctx)
        if ImGui.IsItemClicked(ctx) then fechar = true end
        if sobre then dicaSe( 'Fechar as configurações') end

        local dlX = ImGui.GetWindowDrawList(ctx)
        if sobre then
          ImGui.DrawList_AddRectFilled(dlX, bx, cabY, bx + X_W, cabY + CAB_H,
            Theme.UI.rec, 4)
        end
        local cx, cy = bx + X_W * 0.5, cabY + CAB_H * 0.5
        local cor = sobre and 0xFFFFFFFF or 0x9199A6FF
        ImGui.DrawList_AddLine(dlX, cx - 5, cy - 5, cx + 5, cy + 5, cor, 1.4)
        ImGui.DrawList_AddLine(dlX, cx + 5, cy - 5, cx - 5, cy + 5, cor, 1.4)
      end

      -- Cursor pro fim da linha de cabeçalho, não pro fim do botão: sem
      -- isto o separador seguinte sairia na altura do ×.
      ImGui.SetCursorScreenPos(ctx, cabX, cabY + CAB_H + 4)

      ImGui.Separator(ctx)
      ImGui.Dummy(ctx, 1, 4)

      if ImGui.BeginChild(ctx, 'abas', 138, 0) then
        drawAbas()
        ImGui.EndChild(ctx)
      end

      ImGui.SameLine(ctx, 0, 18)

      if ImGui.BeginChild(ctx, 'conteudo', 0, 0) then
        drawAbaAtual()
        ImGui.EndChild(ctx)
      end

      ImGui.EndChild(ctx)
    end
    ImGui.EndChild(ctx)
  end
  if nCartao > 0 then pcall(ImGui.PopStyleColor, ctx, 1) end

  if fechar then
    painel.aberto = false
    reaper.SetExtState(EXT_SECTION, 'painel.aberto', '0', true)
    encaixe.w = 0   -- a área muda de tamanho: recalcula a escala
  end
end

-- ---------------------------------------------------------- quadro

--- A janela minimizada: só o ícone, clicável, arrastável.
--
--  Sem texto de propósito — em 54px de largura o nome não caberia sem
--  encolher a ponto de não se ler. O ícone sozinho identifica, e a
--  dica diz o resto.
--  @param soPintar  desenha sem reagir ao mouse. Usado no quadro de
--                   transição, quando a janela já não está mais
--                   minimizada mas o SetWindowSize ainda não valeu.
local function drawPastilha(soPintar)
  local largura, altura = ImGui.GetContentRegionAvail(ctx)
  local x0, y0 = ImGui.GetCursorScreenPos(ctx)
  x0, y0 = math.floor(x0), math.floor(y0)
  local dl = ImGui.GetWindowDrawList(ctx)

  local sobre, ativo = false, false
  if not soPintar then
    ImGui.SetCursorScreenPos(ctx, x0, y0)
    ImGui.InvisibleButton(ctx, '##pastilha', math.max(1, largura), math.max(1, altura))
    sobre = ImGui.IsItemHovered(ctx)
    ativo = ImGui.IsItemActive and ImGui.IsItemActive(ctx) or false
  end

  -- CLIQUE x ARRASTO. Restaurar no clique e mover no arrasto disputam o
  -- mesmo botão do mouse, e IsItemClicked dispara já na descida — usá-lo
  -- faria a janela restaurar no instante em que se tentasse arrastá-la.
  -- Então: enquanto segurado, move; ao soltar, restaura SÓ se não tiver
  -- andado.
  if ativo then
    local mx, my = ImGui.GetMousePos(ctx)
    local wx, wy = ImGui.GetWindowPos(ctx)
    if not pastilhaAtivaAntes then
      pastilhaMoveu = false
      chrome.offX, chrome.offY = mx - wx, my - wy
    else
      local novoX, novoY = mx - chrome.offX, my - chrome.offY
      if math.abs(novoX - wx) > 2 or math.abs(novoY - wy) > 2 then
        pastilhaMoveu = true
      end
      if pastilhaMoveu and ImGui.SetWindowPos then
        pcall(ImGui.SetWindowPos, ctx, novoX, novoY)
      end
    end
  elseif pastilhaAtivaAntes and not pastilhaMoveu then
    chrome.minimizado = false
    chrome.restaurando = 2
    chrome.pendW, chrome.pendH = chrome.normalW, chrome.normalH
    encaixe.w = 0
  end
  pastilhaAtivaAntes = ativo

  local corBorda = recording and Theme.UI.rec
    or (sobre and Theme.UI.accent or 0x2A2F3AFF)
  ImGui.DrawList_AddRectFilled(dl, x0, y0, x0 + largura, y0 + altura,
    Theme.UI.bg, 6)
  ImGui.DrawList_AddRect(dl, x0, y0, x0 + largura, y0 + altura, corBorda, 6, 0, 1)

  local TAM = 22
  desenharIconeApp(dl,
    x0 + (largura - TAM) * 0.5, y0 + (altura - TAM) * 0.5, TAM,
    recording and Theme.UI.rec or nil)

  if sobre then
    dicaSe(
      recording and 'LumiBridge — GRAVANDO\n\nClique para voltar ao tamanho normal.'
      or 'LumiBridge\n\nClique para voltar ao tamanho normal.\nArraste para mover.')
  end
end

--- Faz o trabalho de rede que os botões da aba Sobre pediram.
--
--  FORA DO DESENHO, e depois dele. O curl bloqueia por alguns segundos;
--  chamado no meio do quadro, ele congela a interface com metade da tela
--  pintada. Aqui o quadro já saiu inteiro, e o usuário vê "procurando..."
--  antes de a espera começar.
--
--  Método de `painel` pelo mesmo motivo de sempre: o corpo deste módulo
--  está no teto de 200 locais do Lua.
function painel.trabalharAtualizacao()
  local at = painel.atualizacao
  if not at.ocupado then return end
  at.ocupado = false

  local Atualizacao = require('core.atualizacao')
  local temp = reaper.GetResourcePath() .. '/lumibridge_atualizacao.txt'

  if at.instalar and at.achada then
    at.instalar = false
    -- O ARQUIVO QUE ESTÁ RODANDO, perguntado ao REAPER. Adivinhar o
    -- caminho erraria em toda instalação que não fosse a padrão.
    local _, arquivo = reaper.get_action_context()
    if not arquivo or arquivo == '' then
      at.recado = 'não descobri qual arquivo estou rodando'
      return
    end
    local ok, msg = Atualizacao.instalar(at.achada.url, arquivo,
                                         at.achada.versao)
    at.recado = msg
    if ok then at.achada = nil end
    log('atualização: ' .. tostring(msg))
    return
  end

  local achada, msg = Atualizacao.procurar(Version.MANIFESTO,
                                           Version.numero(), temp, Version)
  at.achada, at.recado = achada, msg
  log('atualização: ' .. tostring(msg))
end

-- ---------------------------------------------------------- assistente
--
-- POR QUE ELE EXISTE
--   O programa precisa de quatro coisas para funcionar, e as quatro
--   moram em abas DIFERENTES das configurações: a Tela Personalizada, a
--   porta MIDI, a track onde a automação é gravada e a track de onde sai
--   a forma de onda. Quem acabou de instalar não tem como adivinhar
--   isso — abre, vê uma janela vazia, e conclui que o programa não
--   funciona. Foi o primeiro relato de todo mundo que instalou.
--
--   O assistente é essa lista, um item por tela, na ordem em que um
--   depende do outro. Ele NÃO é um modo à parte do programa: cada passo
--   mexe nos MESMOS ajustes das configurações, com as mesmas funções.
--   Fechar no meio não desfaz nada e não deixa nada pela metade — o que
--   já foi respondido fica respondido.
--
--   Métodos de `painel`, e não funções locais: o corpo deste módulo está
--   no teto de 200 locais do Lua (ver test_integridade).

painel.assist = { aberto = false, passo = 1, recado = nil }
painel.ASSIST_TOTAL = 5

--- O passo `n` já está resolvido?
--
--  O passo 4 é sempre "sim": sem track escolhida a onda cai em
--  "automática", que serve. Perguntar não custa, mas travar o assistente
--  por causa dela custaria.
function painel.assistOk(n)
  if n == 1 then return layout ~= nil end
  if n == 2 then return MidiOut.isReady() end
  if n == 3 then return Timeline.isReady() end
  if n == 4 then return true end
  return painel.assistOk(1) and painel.assistOk(2) and painel.assistOk(3)
end

--- Fecha o assistente e marca que ele já foi visto.
function painel.assistFechar()
  painel.assist.aberto = false
  painel.assist.recado = nil
  reaper.SetExtState(EXT_SECTION, 'assistente_visto', '1', true)
end

--- Cria uma track MIDI para a luz e a escolhe como destino.
--
--  "Escolha a track" não ajuda quem ainda não tem nenhuma, e criar uma
--  na mão significa sair do programa, achar o menu do REAPER e voltar —
--  exatamente o tipo de desvio que faz alguém desistir na primeira noite.
--
--  O NOME É ÚNICO de propósito: a track de gravação é lembrada entre
--  sessões PELO NOME (ver restoreTrack), e duas "LUZ" no mesmo projeto
--  fariam a gravação voltar na track errada depois de fechar o REAPER.
function painel.assistCriarTrack()
  local usados = {}
  for _, t in ipairs(Timeline.listTracks()) do usados[t.name] = true end
  local nome = 'LUZ'
  local n = 2
  while usados[nome] do nome = ('LUZ %d'):format(n); n = n + 1 end

  local onde = reaper.CountTracks(0)
  reaper.Undo_BeginBlock()
  reaper.InsertTrackAtIndex(onde, true)
  local tr = reaper.GetTrack(0, onde)
  if tr then
    reaper.GetSetMediaTrackInfo_String(tr, 'P_NAME', nome, true)
  end
  reaper.Undo_EndBlock('LumiBridge: criar a track da luz', -1)

  refreshTracks()
  Timeline.setTrack(onde, nome)
  reaper.SetExtState(EXT_SECTION, EXT_TRACK, nome, true)
  painel.assist.recado = ('Track "%s" criada e escolhida.'):format(nome)
  log('assistente: track ' .. nome .. ' criada')
end

--- O assistente, no lugar do programa.
--
--  Desenhado como a tela de ativação: um cartão centrado. Texto solto no
--  canto de uma janela vazia parece um erro; um cartão no meio parece
--  uma etapa — e é uma etapa.
function painel.telaDoAssistente()
  local a  = painel.assist
  local dl = ImGui.GetWindowDrawList(ctx)
  local bx, by = ImGui.GetCursorScreenPos(ctx)
  bx, by = math.floor(bx), math.floor(by)

  local janelaW, janelaH = ImGui.GetWindowSize(ctx)
  local CARTAO, ALTURA = 560, 456
  local cx = bx + math.max(16, math.floor(((janelaW or 900) - CARTAO) * 0.5))
  local cy = by + math.max(12, math.floor(((janelaH or 600) - ALTURA) * 0.20))

  ImGui.DrawList_AddRectFilled(dl, cx, cy, cx + CARTAO, cy + ALTURA,
                               Theme.UI.panel, 12)
  ImGui.DrawList_AddRect(dl, cx, cy, cx + CARTAO, cy + ALTURA,
                         0x3F4654FF, 12, 0, 1)

  local px = cx + 30
  local pw = CARTAO - 60          -- largura útil dentro do cartão
  local y  = cy + 24

  -- ---------------------------------------------------------- cabeçalho
  desenharIconeApp(dl, px, y, 32)
  ImGui.SetCursorScreenPos(ctx, px + 46, y - 3)
  local f1 = Theme.pushFont(ImGui, ctx, state.fonts, 22)
  ImGui.TextColored(ctx, Theme.UI.text, 'Primeiros ajustes')
  if f1 then ImGui.PopFont(ctx) end
  ImGui.SetCursorScreenPos(ctx, px + 46, y + 23)
  ImGui.TextColored(ctx, 0x777F8CFF,
    'Quatro respostas e o LumiBridge fica pronto para gravar.')

  y = y + 52
  ImGui.DrawList_AddLine(dl, px, y, px + pw, y, 0x2A2E37FF, 1)
  y = y + 20

  -- ------------------------------------------------------- as bolinhas
  --
  -- Saber QUANTO FALTA é o que faz alguém seguir até o fim em vez de
  -- fechar no segundo passo achando que aquilo não acaba nunca.
  for i = 1, painel.ASSIST_TOTAL do
    local px2 = px + (i - 1) * 22
    local cor = (i < a.passo) and 0x46D07AFF
             or (i == a.passo) and Theme.UI.accent
             or 0x333944FF
    ImGui.DrawList_AddCircleFilled(dl, px2 + 6, y + 6, 5.5, cor)
  end
  ImGui.SetCursorScreenPos(ctx, px + pw - 90, y - 1)
  ImGui.TextColored(ctx, 0x5F6672FF,
    ('passo %d de %d'):format(a.passo, painel.ASSIST_TOTAL))
  y = y + 28

  --- Título e explicação do passo, sempre na mesma altura.
  local function cabecalhoDoPasso(titulo, texto)
    ImGui.SetCursorScreenPos(ctx, px, y)
    local f = Theme.pushFont(ImGui, ctx, state.fonts, 17)
    ImGui.TextColored(ctx, Theme.UI.text, titulo)
    if f then ImGui.PopFont(ctx) end
    ImGui.SetCursorScreenPos(ctx, px, y + 26)
    ImGui.TextColored(ctx, 0x9199A6FF, texto)
  end

  -- A área dos controles começa SEMPRE na mesma altura, independente do
  -- tamanho do texto acima. Botões que dançam de lugar entre um passo e
  -- outro fazem a mão errar o alvo.
  local yc = y + 96

  -- ------------------------------------------------------------ passo 1
  if a.passo == 1 then
    cabecalhoDoPasso('A sua Tela Personalizada',
      'Tudo começa no arquivo .form que você exporta do Lumikit Show.\n'
      .. 'Dele saem os botões, as cores, os grupos e os comandos MIDI —\n'
      .. 'o LumiBridge não inventa nada, ele redesenha a SUA tela.')

    ImGui.SetCursorScreenPos(ctx, px, yc)
    if ImGui.Button(ctx, 'Escolher o arquivo .form', 210, 32) then
      browseForm()
    end
    dica('Abre o seletor de arquivos do REAPER.')

    ImGui.SetCursorScreenPos(ctx, px, yc + 46)
    if layout then
      ImGui.TextColored(ctx, 0x46D07AFF, 'Carregada: ' .. tostring(statusText))
    else
      ImGui.TextColored(ctx, 0x777F8CFF,
        'Nenhuma tela carregada ainda.\n\n'
        .. 'No Lumikit Show: Janela Personalizada > Salvar como, e guarde\n'
        .. 'o .form onde você achar depois.')
    end

  -- ------------------------------------------------------------ passo 2
  elseif a.passo == 2 then
    cabecalhoDoPasso('A porta por onde o MIDI sai',
      'Escolha a porta virtual que o Lumikit já escuta — em geral uma\n'
      .. 'porta do loopMIDI. É por ela que os comandos vão, tanto agora\n'
      .. 'quanto no show, quando só o REAPER estiver tocando.')

    ImGui.SetCursorScreenPos(ctx, px, yc)
    ImGui.SetNextItemWidth(ctx, 300)
    local preview = MidiOut.deviceName or 'selecione a porta de saída'
    if ImGui.BeginCombo(ctx, '##assistporta', preview) then
      if #devices == 0 then
        ImGui.Selectable(ctx, 'nenhuma porta de saída encontrada', false)
      end
      for _, dev in ipairs(devices) do
        if ImGui.Selectable(ctx, dev.name, dev.index == MidiOut.deviceIndex) then
          chooseDevice(dev)
        end
      end
      ImGui.EndCombo(ctx)
    end

    ImGui.SetCursorScreenPos(ctx, px + 312, yc - 2)
    if ImGui.Button(ctx, 'Reler', 74, 26) then refreshDevices() end
    dica('Relê a lista de portas MIDI do sistema.')
    ImGui.SetCursorScreenPos(ctx, px + 392, yc - 2)
    if ImGui.Button(ctx, 'Testar', 74, 26) then MidiOut.sendTestNote() end
    dica('Dispara uma nota de teste. Se o Lumikit acender algo, chegou.')

    ImGui.SetCursorScreenPos(ctx, px, yc + 44)
    if #devices == 0 then
      ImGui.TextColored(ctx, Theme.UI.warn,
        'Nenhuma porta MIDI encontrada neste computador.')
      ImGui.SetCursorScreenPos(ctx, px, yc + 62)
      ImGui.TextColored(ctx, 0x777F8CFF,
        'Instale o loopMIDI (é grátis), crie uma porta, e aponte o\n'
        .. 'Lumikit para ela. Depois volte aqui e clique em Reler.')
    elseif MidiOut.lastError then
      ImGui.TextColored(ctx, Theme.UI.warn, MidiOut.lastError)
    elseif MidiOut.lastMessage then
      ImGui.TextColored(ctx, 0x46D07AFF,
        ('Enviadas %d mensagens de teste por %s.')
          :format(MidiOut.sentCount, MidiOut.deviceName or '?'))
    elseif MidiOut.isReady() then
      ImGui.TextColored(ctx, 0x777F8CFF,
        'Clique em Testar para conferir se o Lumikit está recebendo.')
    end

  -- ------------------------------------------------------------ passo 3
  elseif a.passo == 3 then
    cabecalhoDoPasso('A track onde a luz é gravada',
      'A automação vai para uma track MIDI do seu projeto, separada do\n'
      .. 'áudio. É essa track que, no show, entrega o MIDI ao Lumikit —\n'
      .. 'com ou sem o LumiBridge aberto.')

    ImGui.SetCursorScreenPos(ctx, px, yc)
    ImGui.SetNextItemWidth(ctx, 300)
    local pt = Timeline.trackName or 'selecione a track de destino'
    if ImGui.BeginCombo(ctx, '##assisttrack', pt) then
      if #tracks == 0 then
        ImGui.Selectable(ctx, 'nenhuma track no projeto', false)
      end
      for _, t in ipairs(tracks) do
        if ImGui.Selectable(ctx, t.name, t.index == Timeline.trackIndex) then
          Timeline.setTrack(t.index, t.name)
          reaper.SetExtState(EXT_SECTION, EXT_TRACK, t.name, true)
          painel.assist.recado = nil
        end
      end
      ImGui.EndCombo(ctx)
    end

    ImGui.SetCursorScreenPos(ctx, px + 312, yc - 2)
    if ImGui.Button(ctx, 'Reler', 74, 26) then refreshTracks() end
    dica('Relê a lista de tracks do projeto.')
    ImGui.SetCursorScreenPos(ctx, px + 392, yc - 2)
    if ImGui.Button(ctx, 'Criar uma', 74, 26) then
      painel.assistCriarTrack()
    end
    dica('Cria uma track MIDI chamada LUZ no fim do projeto e a escolhe.')

    -- APONTAR A SAÍDA DA TRACK, que é o passo que ninguém descobre
    -- sozinho: sem ele a automação existe e não sai da máquina.
    ImGui.SetCursorScreenPos(ctx, px, yc + 42)
    if Timeline.isReady() and MidiOut.deviceIndex then
      if ImGui.Button(ctx, ('Mandar esta track para %s')
           :format(MidiOut.deviceName or 'a porta escolhida'), 300, 30) then
        Timeline.setMidiHardwareOut(MidiOut.deviceIndex, 0)
        Timeline.armForVirtualKeyboard()
        painel.assist.recado = 'Saída da track apontada para '
          .. tostring(MidiOut.deviceName) .. '.'
        log('assistente: ' .. painel.assist.recado)
      end
      dica('Liga a saída MIDI da track na porta que o Lumikit escuta.\n'
        .. 'Sem isto, o REAPER toca a automação e nada sai do computador.')
    end

    ImGui.SetCursorScreenPos(ctx, px, yc + 82)
    if painel.assist.recado then
      ImGui.TextColored(ctx, 0x46D07AFF, painel.assist.recado)
    elseif not Timeline.isReady() then
      ImGui.TextColored(ctx, 0x777F8CFF,
        'Nenhuma track escolhida. Se o projeto ainda não tem uma track\n'
        .. 'para a luz, o botão "Criar uma" resolve.')
    else
      ImGui.TextColored(ctx, 0x777F8CFF,
        'Gravando em "' .. tostring(Timeline.trackName) .. '".')
    end

  -- ------------------------------------------------------------ passo 4
  elseif a.passo == 4 then
    cabecalhoDoPasso('A track que desenha a onda',
      'Para você enxergar a batida enquanto programa, o LumiBridge\n'
      .. 'desenha a forma de onda de uma track. Aponte a que tem a GUIA\n'
      .. 'da música. Este passo é opcional.')

    ImGui.SetCursorScreenPos(ctx, px, yc)
    ImGui.SetNextItemWidth(ctx, 300)
    local ondaRotulo = (waveTrack ~= '' and waveTrack) or 'automática'
    if ImGui.BeginCombo(ctx, '##assistonda', ondaRotulo) then
      if ImGui.Selectable(ctx, 'automática', waveTrack == '') then
        waveTrack = ''
        Waveform.setTrack('', nil)
        Waveform.reset()
        reaper.SetExtState(EXT_SECTION, 'wave_track', '', true)
      end
      for _, t in ipairs(tracks) do
        -- MARCA QUEM TEM ÁUDIO. Numa lista de vinte tracks, a que serve
        -- é justamente a que tem som, e o nome nem sempre diz.
        local rotulo = Waveform.hasAudio(t.index) and (t.name .. '   ♪')
                       or t.name
        if ImGui.Selectable(ctx, rotulo, t.name == waveTrack) then
          waveTrack = t.name
          Waveform.setTrack(t.name, t.index)
          Waveform.reset()
          reaper.SetExtState(EXT_SECTION, 'wave_track', waveTrack, true)
        end
      end
      ImGui.EndCombo(ctx)
    end

    ImGui.SetCursorScreenPos(ctx, px, yc + 44)
    ImGui.TextColored(ctx, 0x777F8CFF,
      'Em "automática" ele usa a primeira track com áudio no trecho —\n'
      .. 'o que quase sempre acerta. Aponte na mão quando o projeto tiver\n'
      .. 'várias tracks de áudio e você quiser ver uma delas em especial.')

  -- ------------------------------------------------------------ passo 5
  else
    cabecalhoDoPasso('Pronto',
      'É isto que o programa precisa saber. Se algo ficou vermelho,\n'
      .. 'volte — sem esses três itens ele abre, mas não grava.')

    --- Uma linha da conferência.
    local function conferir(yy, ok, certo, errado)
      local cor = ok and 0x46D07AFF or Theme.UI.warn
      ImGui.DrawList_AddCircleFilled(dl, px + 5, yy + 8, 4, cor)
      ImGui.SetCursorScreenPos(ctx, px + 18, yy)
      ImGui.TextColored(ctx, ok and 0xB9C0CCFF or Theme.UI.warn,
                        ok and certo or errado)
    end

    conferir(yc, painel.assistOk(1),
      'Tela Personalizada carregada.',
      'Falta a Tela Personalizada (.form).')
    conferir(yc + 24, painel.assistOk(2),
      'Porta de saída: ' .. tostring(MidiOut.deviceName),
      'Falta escolher a porta MIDI.')
    conferir(yc + 48, painel.assistOk(3),
      'Gravando em: ' .. tostring(Timeline.trackName),
      'Falta escolher a track de gravação.')
    conferir(yc + 72, true,
      'Onda: ' .. ((waveTrack ~= '' and waveTrack) or 'automática'),
      '')

    -- AS REGIÕES não são ajuste nenhum — são do projeto do REAPER —,
    -- mas sem elas a janela abre sem nenhuma música para escolher, e o
    -- programa parece quebrado pelo mesmo motivo de antes.
    ImGui.SetCursorScreenPos(ctx, px, yc + 106)
    if #regions == 0 then
      ImGui.TextColored(ctx, Theme.UI.warn,
        'Este projeto ainda não tem regiões.')
      ImGui.SetCursorScreenPos(ctx, px, yc + 124)
      ImGui.TextColored(ctx, 0x777F8CFF,
        'Cada música é uma REGIÃO do REAPER. Crie uma por música e elas\n'
        .. 'aparecem no campo de busca da barra, prontas para gravar.')
    else
      ImGui.TextColored(ctx, 0x777F8CFF,
        ('%d região(ões) no projeto — cada uma é uma música na barra.')
          :format(#regions))
    end
  end

  -- ------------------------------------------------------------- rodapé
  local yr = cy + ALTURA - 60
  ImGui.DrawList_AddLine(dl, px, yr, px + pw, yr, 0x2A2E37FF, 1)

  ImGui.SetCursorScreenPos(ctx, px, yr + 16)
  if ImGui.Button(ctx, a.passo == painel.ASSIST_TOTAL and 'Fechar'
                       or 'Pular por agora', 130, 30) then
    painel.assistFechar()
  end
  dica('Fecha o assistente. O que você já respondeu fica guardado, e\n'
    .. 'ele volta pelo botão no topo das configurações.')

  if a.passo > 1 then
    ImGui.SetCursorScreenPos(ctx, px + pw - 224, yr + 16)
    if ImGui.Button(ctx, 'Voltar', 100, 30) then
      a.passo = a.passo - 1
      a.recado = nil
    end
  end

  ImGui.SetCursorScreenPos(ctx, px + pw - 116, yr + 16)
  if a.passo < painel.ASSIST_TOTAL then
    if ImGui.Button(ctx, 'Continuar', 116, 30) then
      a.passo = a.passo + 1
      a.recado = nil
      -- Relê as listas ao ENTRAR no passo que as usa: quem abriu o
      -- assistente e foi criar a porta ou a track no meio do caminho
      -- encontraria a lista de antes.
      if a.passo == 2 then refreshDevices() end
      if a.passo == 3 or a.passo == 4 then refreshTracks() end
    end
  else
    if ImGui.Button(ctx, 'Concluir', 116, 30) then painel.assistFechar() end
  end

  -- O cursor de layout sai de baixo do cartão: o que vier depois desenha
  -- a partir dele, e não por cima.
  ImGui.SetCursorScreenPos(ctx, bx, cy + ALTURA + 20)
  ImGui.Dummy(ctx, 1, 1)
end

local function frame()
  -- ZERADO NO COMEÇO DO QUADRO, e não em handleShortcuts.
  --
  -- Quem marca são os campos de texto, ao serem desenhados; quem lê é
  -- handleShortcuts, mais adiante no mesmo quadro. Se a limpeza ficasse
  -- lá, bastaria a janela perder o foco (handleShortcuts sai logo na
  -- primeira linha) para a marca ficar presa em verdadeiro — e os
  -- atalhos parariam de funcionar de vez ao voltar o foco.
  campoTextoAtivo = false

  -- Redimensionamento pendente: só aqui, com a janela já aberta pelo
  -- Begin, o SetWindowSize tem efeito.
  if chrome.pendW and ImGui.SetWindowSize then
    pcall(ImGui.SetWindowSize, ctx, chrome.pendW, chrome.pendH)
    chrome.pendW, chrome.pendH = nil, nil
  end

  if chrome.minimizado then
    drawPastilha(false)
    return
  end

  -- QUADRO DE TRANSIÇÃO. O SetWindowSize acima só tem efeito no quadro
  -- SEGUINTE: logo depois de restaurar, a janela ainda tem o tamanho da
  -- pastilha. Desenhar a barra de título nela punha o × bem em cima do
  -- ícone — era o "X que aparecia rapidinho" ao restaurar. Enquanto ela
  -- não tiver crescido, continua-se pintando a pastilha, só que sem
  -- reagir ao mouse (o clique que restaurou já foi consumido).
  --
  -- As DUAS condições importam: o contador sozinho pintaria a pastilha
  -- por um quadro mesmo se a janela já tivesse crescido, e a largura
  -- sozinha transformaria em pastilha uma janela que o usuário tivesse
  -- encolhido na mão.
  if chrome.restaurando > 0 then
    chrome.restaurando = chrome.restaurando - 1
    local larguraJanela = ImGui.GetWindowSize(ctx)
    if (larguraJanela or 0) < 200 then
      drawPastilha(true)
      return
    end
  end

  -- O trabalho de rede pedido no quadro anterior, antes de desenhar
  -- este: assim o "procurando..." já esteve na tela quando a espera
  -- começa.
  painel.trabalharAtualizacao()

  drawBarraTitulo()

  -- SEM LICENÇA, NADA DE PROGRAMA.
  --
  -- Depois da barra de título, e não antes: sem ela não haveria como
  -- mover nem fechar a janela, e alguém sem chave ficaria com um
  -- retângulo preso na tela.
  if not chrome.lic.ativa then
    chrome.telaDeAtivacao()
    return
  end

  -- O ASSISTENTE, no lugar do programa enquanto estiver aberto.
  --
  -- Aqui e não flutuando por cima: com a janela vazia atrás, um cartão
  -- translúcido sobre nada parece um erro de desenho. E o assistente é
  -- justamente para quem tem a janela vazia.
  if painel.assist.aberto then
    painel.telaDoAssistente()
    return
  end

  drawToolbar()

  -- Capturado AQUI — canto e tamanho da área útil logo após a barra de
  -- ferramentas, antes do canvas mexer no cursor — para o painel de
  -- configurações (desenhado por último, ver o fim desta função) saber
  -- onde flutuar por cima, mesmo tendo sido calculado bem antes dele.
  local painelX, painelY = ImGui.GetCursorScreenPos(ctx)
  local painelW, painelH = ImGui.GetContentRegionAvail(ctx)

  if not layout then
    ImGui.Dummy(ctx, 1, 20)
    ImGui.Text(ctx, 'Abra a Tela Personalizada — o arquivo .form exportado do Lumikit Show.')
    drawSettingsPanel(painelX, painelY, painelW, painelH)
    return
  end

  -- AS FAIXAS VÊM ANTES DO CANVAS, e é isso que faz a divisão de altura
  -- funcionar sozinha: o que sobra é medido lá dentro (ver a escala
  -- automática), então tirar altura aqui já reencaixa o painel do .form
  -- sem ninguém precisar descontar número nenhum.
  -- AO LADO: as faixas viram uma coluna à direita e o painel fica com a
  -- altura toda. Empilhado, o .form encolhe até caber na altura que
  -- sobra e — sendo quase 2:1 — passa a ser limitado pela ALTURA, com
  -- uma faixa em branco à direita. Em coluna, quem limita é a largura,
  -- e a lista de controles ganha a vertical inteira.
  --
  -- Precisa de espaço para os dois: numa janela estreita, dividir daria
  -- duas colunas inúteis em vez de uma útil.
  local larguraFaixas = 0
  if faixas.abertas and faixas.lado and not faixas.inteira
     and painelW > 760 then
    larguraFaixas = math.floor(math.max(320,
      math.min(painelW - 400, faixas.largura or painelW * 0.42)))
  end

  local tFaixas = cronometro()
  local alturaFaixas = 0
  if larguraFaixas > 0 then
    -- Desenhadas no lugar delas e o cursor volta ao canto: quem mede o
    -- que sobrou é o canvas, logo abaixo, e ele mede a partir daqui.
    -- UM PIXEL DE FOLGA na borda direita. Um item que termina EXATAMENTE
    -- no limite da região faz a barra de rolagem aparecer num quadro e
    -- sumir no seguinte — e cada aparição muda o espaço disponível, que
    -- muda a escala, que muda o desenho.
    ImGui.SetCursorScreenPos(ctx,
      painelX + painelW - larguraFaixas - 1, painelY)
    drawFaixas(painelH, larguraFaixas)
    ImGui.SetCursorScreenPos(ctx, painelX, painelY)
  else
    alturaFaixas = drawFaixas(painelH) or 0
  end
  medir('faixas', tFaixas)

  -- DIVISÓRIA VERTICAL. Quanto cada um merece muda com a música e com o
  -- momento da programação, então é arrastável — igual à pega de altura
  -- do modo empilhado.
  if larguraFaixas > 0 then
    local dx = painelX + painelW - larguraFaixas - 6
    ImGui.SetCursorScreenPos(ctx, dx, painelY)
    -- Um pixel a menos que a altura toda: um item que termina EXATAMENTE
    -- na borda já conta como conteúdo maior que a janela.
    ImGui.InvisibleButton(ctx, '##divFaixas', 6, math.max(1, painelH - 1))
    local sobreD = ImGui.IsItemHovered(ctx)
    local ativaD = ImGui.IsItemActive and ImGui.IsItemActive(ctx)
    if sobreD or ativaD then
      ImGui.DrawList_AddRectFilled(ImGui.GetWindowDrawList(ctx),
        dx + 2, painelY, dx + 4, painelY + painelH, Theme.UI.accent)
      if ImGui.SetMouseCursor then
        local cur = Compat.const(ImGui, 'MouseCursor_ResizeEW', nil)
        if cur then pcall(ImGui.SetMouseCursor, ctx, cur) end
      end
      if sobreD then
        dicaSe(
          'Arraste para dividir a tela entre a Tela Personalizada e a\nProgramação MIDI.')
      end
    end
    if ativaD then
      faixas.largura = math.max(320,
        (painelX + painelW) - ImGui.GetMousePos(ctx))
      encaixe.w = 0
      faixas.salvarEm = (reaper.time_precise and reaper.time_precise() or 0) + 0.5
    end
    ImGui.SetCursorScreenPos(ctx, painelX, painelY)
  end

  -- INTEIRA: o painel do .form não é DESENHADO — e é só isso.
  --
  -- Aqui havia um `return`, e ele levava junto tudo o que vem depois
  -- neste quadro: a leitura dos cliques, o encerramento da gravação no
  -- stop, o `quadro.tocava`, o espelho e os atalhos de teclado. O sintoma
  -- foi "com o .form escondido, os botões de transporte não funcionam" —
  -- e não era do transporte: era o quadro terminando cedo demais.
  --
  -- Já aconteceu antes neste arquivo, com um `return` das configurações
  -- que levava a barra inteira. Esconder algo é pular o DESENHO daquilo,
  -- nunca o resto do quadro.
  local escondeuPainel = faixas.inteira and faixas.abertas

  state.hovered = nil

  -- Shift para o passo fino da roda do mouse.
  state.shiftDown = false
  do
    local modShift = Compat.const(ImGui, 'Mod_Shift', nil)
    if modShift and modShift ~= 0 and ImGui.IsKeyDown then
      local ok, down = pcall(ImGui.IsKeyDown, ctx, modShift)
      state.shiftDown = ok and down or false
    end
  end

  recheckBindings()

  local playingNow = Transport.isPlaying()

  -- PLAY PURO: a timeline assume tudo.
  --
  -- Ao começar a tocar sem gravar, o que estava clicado na tela deixa
  -- de valer — reproduzir é reproduzir. Sem isso, um botão aceso antes
  -- do play continuava aceso na tela disputando com a programação, e a
  -- interface parava de refletir a música.
  if playingNow and not quadro.tocava and not recording then
    meus = {}
    faderMov = {}
    log('play: a timeline assume o controle da tela')
  end

  -- ABERTURA DE MÚSICA — só quando a região está VAZIA.
  --
  -- Música nova: ao começar a tocar com o REC ligado, escreve o release
  -- no primeiro quadradinho e abre as linhas dos botões que você deixou
  -- marcados. A programação larga com eles acesos.
  --
  -- Música já programada: NADA disto acontece. O REC apenas ouve, e só
  -- o clique escreve. Escrever a abertura por cima de um trabalho já
  -- feito era o que criava notas do nada ao apertar REC.
  if playingNow and not quadro.tocava and recording and recorder
     and Timeline.isReady() and preparo.auto and region then
    local jaGravado = Timeline.countNotesIn(region.startTime, region.endTime)

    if jaGravado == 0 then
      local armed = {}
      for tag, on in pairs(session.active) do
        if on and not session.faderTags[tag] then
          local e = session.byTag[tag]
          if e and e.commands and #e.commands > 0 then armed[#armed + 1] = e end
        end
      end
      table.sort(armed, function(a, b) return (a.tag or 0) < (b.tag or 0) end)

      local release = preparo.release and Session.findRelease(session) or nil
      local out = Recorder.openSong(recorder, release, armed,
                                    Timeline.timeToQN(region.startTime))
      if #out > 0 then Timeline.write(out) end

      if release or #armed > 0 then
        log(('abertura: %s%d botão(ões)')
          :format(release and 'release + ' or '', #armed))
      end
    end
  end

  -- FADER SOLTO: grava o ponto onde ele parou.
  --
  -- O ImGui só sabe que o arrasto acabou quando o botão do mouse é
  -- solto; até lá, o valor vai só para o Lumikit.
  -- DESLIZE DOS FADERS.
  --
  -- A roda define o destino; é AQUI que o fader percorre o caminho até
  -- ele, passando por cada valor. Sem esta chamada, o destino era
  -- definido e ninguém o alcançava — o fader saltava de 0 para 12 para
  -- 25, e tanto o Lumikit quanto a gravação viam degraus.
  if session then
    local dt = quadro.media or 0.016
    local desliza = Session.rampFaders(session, dt)

    for _, intent in ipairs(desliza) do
      if MidiOut.enabled and intent.commands then
        MidiOut.sendAll(intent.commands, intent.value)
      end

      -- As leituras do deslize contam como movimento, para o gesto ser
      -- gravado do começo ao fim.
      if intent.faderTag and intent.faderValue then
        local e = session.byTag[intent.faderTag]
        if e then
          local mov = faderMov[intent.faderTag]
          if not mov then
            mov = { element = e, pontos = {} }
            faderMov[intent.faderTag] = mov
          end
          local rc = context()
          mov.pontos[#mov.pontos + 1] =
            { qn = rc.qn, value = intent.faderValue }
          mov.ultimo = reaper.time_precise and reaper.time_precise() or 0
          liveWriteFader(mov, rc, intent.faderValue)
        end
      end
    end
  end

  descarregarGestos(false)

  -- CRESCIMENTO DAS NOTAS AO VIVO.
  if playingNow then
    local ctxNow = context()
    quadro.ultimaQN = ctxNow.qn
  end

  if recording and recorder and playingNow and Timeline.isReady() then
    local ctxLive = context()
    local grow = Recorder.growLive(recorder, ctxLive.qn)
    if #grow > 0 then
      Timeline.write(grow)
      -- Registrado com parcimônia: o crescimento acontece muitas vezes
      -- por segundo, e anotar cada passo afogaria o resto do registro.
      for _, it in ipairs(grow) do
        if math.floor(it.endQN) % 4 == 0 then
          log(('  cresce nota %-3s até %.3f QN'):format(tostring(it.pitch), it.endQN))
        end
      end
    end
  end

  -- PARAR ENCERRA A GRAVAÇÃO, como no REAPER.
  --
  -- O REC não é um interruptor que fica ligado: ele arma e dispara a
  -- gravação, e o stop a encerra. Sem isto, o REC continuava marcado
  -- depois do stop e o play seguinte voltava a gravar sem que ninguém
  -- tivesse pedido — regravando por cima do que acabou de ser feito.
  --
  -- A condição exige `quadro.tocava`: no quadro em que o REC é apertado o
  -- play ainda não começou, e sem essa guarda a gravação se encerraria
  -- no instante em que fosse iniciada.
  if recording and quadro.tocava and not playingNow then
    stopRecording()
    log('gravação encerrada pelo stop')
  end

  -- O STOP VOLTA PRA MÚSICA DO LUMIBRIDGE, NÃO PRA ONDE OUTRA FERRAMENTA
  -- DEIXOU O CURSOR.
  --
  -- O "Stop" nativo do REAPER devolve o cursor de edição pra onde ele
  -- estava QUANDO O PLAY COMEÇOU — não necessariamente pra música
  -- escolhida aqui. Se outro gerenciador de regiões tiver deixado o
  -- cursor posicionado numa música diferente antes do play, o Stop
  -- "puxava" de volta pra lá, como se o LumiBridge não estivesse no
  -- comando.
  --
  -- Corrigido no PONTO GERAL — `quadro.tocava and not playingNow` — e não
  -- só no botão Stop daqui: pega qualquer forma de parar (este botão, o
  -- Espaço, o transporte nativo do REAPER, um controlador MIDI), sempre
  -- com a mesma correção. PAUSA fica de fora de propósito
  -- (Transport.isPaused()): pausar deve preservar a posição; só PARAR
  -- deve voltar para o início da música escolhida.
  if quadro.tocava and not playingNow and not Transport.isPaused()
     and region and region.isRegion then
    Transport.setPosition(region.startTime, false)
  end

  quadro.tocava = playingNow

  -- RETORNO VISUAL durante o play: acende os botões conforme a
  -- programação gravada passa pelo cursor.
  --
  -- Só quando NÃO se está gravando: durante a gravação o estado da tela
  -- é o que você acabou de clicar, e sobrescrevê-lo com o que está no
  -- disco faria os botões piscarem contra o seu próprio comando.
  --
  -- A leitura varre as notas do item, então é feita ~15x por segundo em
  -- vez de a cada quadro.
  -- PARADO, O ESPELHO TAMBÉM VALE — quando o cursor SE MOVE.
  --
  -- Antes ele só rodava tocando, e a tela ficava mostrando o estado
  -- antigo até alguém dar play: arrastar o cursor pela forma de onda
  -- não mostrava o que está gravado ali. É o oposto do que se espera de
  -- uma régua de tempo — e é preciso ver a programação daquele ponto
  -- justamente para decidir o que regravar.
  --
  -- Só quando MUDA de posição, não a cada quadro parado: sem isso, o
  -- espelho reescreveria o estado da tela sem parar e desfaria os
  -- cliques de marcação da abertura assim que fossem feitos.
  local paradoEmPosicaoNova = false
  if espelho.seguir and session and not Transport.isPlaying() and not recording then
    local pos = Transport.position()
    if espelho.ultimaPos == nil or math.abs(pos - espelho.ultimaPos) > 0.001 then
      espelho.ultimaPos = pos
      paradoEmPosicaoNova = true
      -- Mudou de ponto: as marcas do ponto anterior não valem mais. O
      -- espelho vai reescrever a tela com o que está gravado AQUI, e
      -- manter as marcas antigas faria o REC escrever no lugar errado
      -- o que foi clicado noutro trecho.
      espelho.marcados = {}
    end
  end

  local tEspelho = cronometro()
  if espelho.seguir and session
     and (Transport.isPlaying() or paradoEmPosicaoNova) then
    local now = reaper.time_precise and reaper.time_precise() or 0
    if paradoEmPosicaoNova then espelho.ate = 0 end
    if now >= espelho.ate then
      -- Dez leituras por segundo bastam para o olho, e cada uma varre
      -- o item inteiro. Quinze eram um terço mais trabalho sem ganho
      -- perceptível.
      espelho.ate = now + 0.10
      local pos = Transport.position()

      -- NO INÍCIO DA MÚSICA, LÊ DEPOIS DO RELEASE.
      --
      -- A primeira célula da região é reservada ao Release All (ver
      -- Recorder.openSong): ali dentro a única coisa "soando" é o
      -- release, e a abertura da música — o que fica ligado a partir
      -- dela — só começa na célula seguinte. Parar o cursor no começo
      -- mostrava, portanto, TUDO APAGADO, que é o oposto da verdade:
      -- a música abre com controles ligados.
      --
      -- O ponto de leitura sai da NOTA do release, não de uma conta com
      -- a grade do projeto: a grade muda depois da gravação e a conta
      -- erraria justamente aí (ver Timeline.afterReleaseTime).
      --
      -- SÓ PARADO. Tocando, o espelho também MANDA MIDI ao Lumikit
      -- (ver espelho.envia adiante), e adiantar o ponto de leitura mandaria
      -- a abertura da música antes da hora — trocar um erro visual por
      -- um erro no palco.
      local puloDoRelease = false
      if paradoEmPosicaoNova and region and region.isRegion then
        local rel = Session.findRelease(session)
        local pitchRel
        for _, cmd in ipairs(rel and rel.commands or {}) do
          if (cmd.status & 0xF0) == 0x90 then pitchRel = cmd.data1 break end
        end
        local depois = pitchRel
          and Timeline.afterReleaseTime(region.startTime, pitchRel)
        if depois and pos >= region.startTime - 0.01 and pos < depois then
          pos = depois
          puloDoRelease = true
        end
      end

      -- Durante a gravação, o espelho NÃO toca nos controles que você
      -- está gravando: o estado deles é o que você acabou de clicar, e
      -- sobrescrevê-lo com o disco faria os botões piscarem contra o
      -- seu próprio comando.
      -- O espelho também não toca nos RIVAIS do que você está gravando.
      --
      -- Sem isso, a nota antiga — que ainda soa por um instante no
      -- cursor, antes de o corte alcançá-la — reacendia o botão
      -- anterior, e os dois do mesmo grupo apareciam acesos ao mesmo
      -- tempo. Num grupo "apenas um ativo" isso é um estado impossível.
      --
      -- FADER EM MOVIMENTO (arrasto ou roda em andamento) também fica
      -- fora do espelho por este mesmo motivo: o espelho aplica os
      -- valores de CC gravados a cada 66 ms, e puxava o fader de volta
      -- enquanto o usuário ainda estava arrastando.
      --
      -- QUEM MANDA, conforme o modo:
      --
      --   REC  -> o que VOCÊ clica tem prioridade, mas SÓ no que você
      --           de fato mexeu nesta gravação (`meus`, que também
      --           cobre faders — ver as marcas nos ramos 'fader' e
      --           'wheel' acima). Um fader que você ainda não tocou
      --           continua seguindo a programação normalmente, igual
      --           no Play — é assim que dá pra ver a música tocando
      --           sozinha enquanto você grava só o que quer mudar.
      --
      --   PLAY -> a timeline manda em tudo. Reproduzir é reproduzir; o
      --           que estava clicado na tela não conta.
      local skip = nil
      if next(faderMov) then
        skip = {}
        for tag in pairs(faderMov) do skip[tag] = true end
      end

      if recording then
        skip = skip or {}
        -- Tudo o que foi tocado nesta gravação continua seu até o stop.
        for tag in pairs(meus) do skip[tag] = true end
      end

      if recording and recorder then
        skip = skip or {}
        for tag in pairs(recorder.open) do
          skip[tag] = true
          for rival in pairs(Rules.exclusivePeers(session.ruleIndex, tag)) do
            skip[rival] = true
          end
        end
      end

      local soando = Timeline.soundingAt(pos)
      local mudou = Session.applySounding(session, soando,
                                          Timeline.ccValuesAt(pos), skip)

      -- DIAGNÓSTICO do espelho PARADO, uma linha por movimento do
      -- cursor — nunca durante a reprodução, que o chamaria dez vezes
      -- por segundo e afogaria o registro.
      --
      -- Registra o que separa "não rodou" de "rodou e não achou nada":
      -- sem isso, os dois casos chegam aqui como "não acende", e é
      -- justamente essa distinção que aponta se o problema é a track
      -- escolhida, a posição lida ou a programação daquele ponto.
      if paradoEmPosicaoNova and painel.verbose then
        local quantas = 0
        for _ in pairs(soando) do quantas = quantas + 1 end
        local acesos = 0
        for _, on in pairs(session.active) do if on then acesos = acesos + 1 end end
        log(('espelho parado em %s — %d altura(s) soando, %d controle(s) aceso(s)%s%s')
          :format(Transport.formatTime(pos), quantas, acesos,
                  puloDoRelease and '  (lido após o release)' or '',
                  Timeline.isReady() and '' or '  (SEM TRACK ESCOLHIDA)'))
      end

      -- O palco acompanha a programação já gravada.
      --
      -- SÓ COM O PLAY RODANDO, e nunca durante a gravação.
      --
      -- Os controles são toggle: o Lumikit alterna a cada Note On. O
      -- espelho reenviando as mesmas notas DESFAZIA o que o usuário
      -- acabara de clicar — a luz acendia e apagava no mesmo instante, e
      -- o sintoma era "o Lumikit parou de receber Note On". Os Control
      -- Change não sofriam disso porque são valor absoluto, não
      -- alternância: por isso só os faders continuavam funcionando.
      -- E SÓ QUANDO A TRACK NÃO ESTÁ ENTREGANDO SOZINHA.
      --
      -- Se a track manda o MIDI dela para a mesma porta que usamos, o
      -- REAPER já toca cada nota da programação — e o espelho mandando
      -- de novo faz o Lumikit receber DOIS Note On no mesmo botão.
      -- Sendo toggle, ele acende e apaga: o botão fica como estava.
      --
      -- Foi assim que apareceu: tocando pelo LumiBridge, os botões
      -- acendiam na nossa tela e não no Lumikit nem no 3D; o mesmo
      -- arquivo tocado só pelo REAPER acendia. A nossa tela é desenhada
      -- do que está gravado, não do MIDI, e por isso não sofria.
      --
      -- Quem cede é o espelho, e não a track: a track toca no tempo
      -- exato do evento, e o espelho lê dez vezes por segundo — até
      -- cem milissegundos de atraso, num palco.
      if espelho.envia and not recording and Transport.isPlaying() then
        if espelho.duplicaria() then
          -- Uma vez por vez que a situação aparece, e não dez por
          -- segundo: calar sem dizer nada seria trocar um defeito
          -- visível por um invisível.
          if not espelho.avisouDuplicata then
            espelho.avisouDuplicata = true
            log('a track já manda o MIDI dela para a mesma porta: o '
              .. 'espelho fica quieto na reprodução para o Lumikit não '
              .. 'receber cada nota duas vezes')
          end
        else
          espelho.avisouDuplicata = false
          for _, m in ipairs(mudou) do
            MidiOut.sendAll(m.element.commands)
          end
        end
      end
    end
  end
  medir('espelho', tEspelho)
  handleShortcuts()

  -- Declarado aqui fora porque o laço de eventos roda depois do canvas
  -- (ver abaixo). Fica nil quando o painel está escondido — e nesse caso
  -- só os acionamentos da lista de faixas entram na fila.
  -- UMA SESSÃO DE DESFAZER ABERTA SEM GRAVAÇÃO É VAZAMENTO.
  --
  -- `Timeline.editar` não abre bloco próprio quando há sessão em curso —
  -- e está certo: fragmentar uma gravação em dezenas de Ctrl+Z seria
  -- pior. Só que a sessão abre no REC e fecha no stop, e se o stop não
  -- chegar ao fim (um erro no meio, um caminho que retorna antes) ela
  -- fica aberta para sempre. A partir daí NENHUMA edição manual entra em
  -- bloco, e o desfazer para de funcionar em tudo — sem aviso, e até
  -- fechar a janela.
  --
  -- Aqui é o único lugar que sabe as duas coisas ao mesmo tempo: que não
  -- se está gravando e que a sessão continua aberta.
  if not recording and Timeline.inSession() then
    Timeline.endSession('LumiBridge: gravação')
    log('sessão de desfazer estava aberta sem gravação; fechei')
  end

  local eventosDoForm = nil
  local canvasAbriu = false

  local tCanvas = cronometro()
  -- Com o painel escondido pelas faixas, não há canvas para desenhar —
  -- mas TUDO acima já rodou, que é o que importa.
  -- QUANTAS VEZES O CANVAS NÃO ABRIU. BeginChild devolve false quando a
  -- área é degenerada ou está toda recortada; nesses quadros o .form
  -- simplesmente não é desenhado, e um painel que some por um quadro e
  -- volta no seguinte é uma piscada — que também se descreve como
  -- "pulando".
  if not escondeuPainel then quadro.canvasPedido = (quadro.canvasPedido or 0) + 1 end
  if not escondeuPainel
     and ImGui.BeginChild(ctx, 'canvas',
                          larguraFaixas > 0 and -(larguraFaixas + 6) or 0,
                          0) then
    canvasAbriu = true
    -- ESCALA AUTOMÁTICA, medida POR FORA do canvas — e é isso que a faz
    -- parar de pular.
    --
    -- Ela era medida AQUI DENTRO, com GetContentRegionAvail, pelo motivo
    -- certo: descontar um número fixo lá de cima errava sempre que a
    -- barra mudava de altura. Só que a área DE DENTRO de um filho depende
    -- de uma coisa que o próprio desenho decide — se cabe uma barra de
    -- rolagem. E aí:
    --
    --   o .form cabe raspando   -> sem barra   -> área cheia
    --   desenhado na área cheia -> passa 1px   -> aparece a barra
    --   com a barra             -> área 14px menor -> reencaixa menor
    --   menor                   -> a barra some -> volta ao começo
    --
    -- Um ciclo por quadro, e a cada volta cento e poucos botões trocam de
    -- tamanho: a tela inteira pulando. Com as faixas sozinhas não há
    -- .form para reescalar, e por isso ali estava tudo bem — foi essa
    -- diferença que entregou o defeito.
    --
    -- A zona morta de meio por cento não segura isso: a barra de rolagem
    -- muda a área em quase dois por cento.
    --
    -- As medidas de fora não têm esse laço: saem da região do PAINEL, que
    -- é decidida antes de qualquer filho existir, menos o que as faixas
    -- tomaram — que elas mesmas informam. Sobrando barra de rolagem por
    -- engano, ela fica; ficar é feio, oscilar é insuportável.
    if layout and opcoes.zoom then
      local aw = painelW - ((larguraFaixas > 0) and (larguraFaixas + 6) or 0)
      local ah = painelH - ((larguraFaixas > 0) and 0 or alturaFaixas)
      if math.abs(aw - encaixe.w) > 2 or math.abs((ah or 0) - encaixe.h) > 2 then
        encaixe.w, encaixe.h = aw, ah or 0
        if aw > 40 and (ah or 0) > 40 then
          -- FOLGA À DIREITA E EMBAIXO, igual à que o arquivo já deixa em
          -- cima.
          --
          -- O conteúdo do .form termina no último pixel do último
          -- controle, então encaixar por ele deixava o painel com margem
          -- de um lado e nada do outro — torto numa janela cheia, e mais
          -- ainda maximizada.
          --
          -- A medida vem do PRÓPRIO ARQUIVO (layout.marginY: onde começa
          -- o primeiro controle), não de um número escolhido aqui. Um
          -- .form que não deixe margem nenhuma continua sem margem, que
          -- é o que ele pede.
          --
          -- Nada muda de lugar: só se reserva espaço no cálculo do
          -- encaixe. A regra "o .form é desenhado como está" continua.
          -- FOLGA NOSSA, IGUAL NOS QUATRO LADOS.
          --
          -- Duas parcelas, e as duas precisam entrar na conta:
          --
          --   M.folga  é a nossa, em pixels de tela. Sai duas vezes
          --                 da largura disponível (uma de cada lado) e o
          --                 desenho começa deslocado dela.
          --   layout.margin é a que o ARQUIVO já deixa antes do primeiro
          --                 controle. Some ao conteúdo para sobrar o
          --                 mesmo do outro lado.
          --
          -- Sem a segunda, um .form que começa em y=8 ficava com 8px a
          -- mais em cima do que embaixo. Sem a primeira, um .form que
          -- começa em 0 colava na borda — que foi o relatado.
          local cabe = math.min(
            (aw - M.folga * 2) /
              (layout.contentWidth + (layout.marginX or 0)),
            (ah - M.folga * 2) /
              (layout.contentHeight + (layout.marginY or 0)))
          cabe = math.max(0.3, math.min(2.0, cabe))

          -- ZONA MORTA: mudança pequena não mexe no layout.
          --
          -- O espaço disponível aqui dentro depende de coisas que o
          -- próprio desenho influencia — se cabe uma barra de rolagem,
          -- quanto a coluna das faixas tomou, o arredondamento de cada
          -- borda. Basta um pixel indo e voltando para a escala mudar,
          -- e a escala muda O DESENHO INTEIRO: com o .form na tela,
          -- cento e poucos botões trocam de tamanho e de lugar a cada
          -- quadro. Não é lentidão, é a tela pulando.
          --
          -- Meio por cento é menos do que o olho vê num botão e mais do
          -- que qualquer tremida de arredondamento. Uma mudança de
          -- verdade — arrastar a divisória, maximizar — passa longe
          -- disso e continua reajustando na hora.
          if math.abs(cabe - state.zoom) > state.zoom * 0.005 then
            state.zoom = cabe
            encaixe.mudou = (encaixe.mudou or 0) + 1
          end
        end
      end
    end

    -- O desenho começa deslocado da folga: é o que a transforma em
    -- margem visível, e não em espaço sobrando só do lado direito.
    do
      local dx, dy = ImGui.GetCursorScreenPos(ctx)
      ImGui.SetCursorScreenPos(ctx, dx + M.folga, dy + M.folga)
    end

    eventosDoForm = Renderer.draw(ImGui, ctx, layout, state)

    ImGui.EndChild(ctx)
  end
  medir('canvas', tCanvas)
  if not escondeuPainel and not canvasAbriu then
    quadro.canvasFalhou = (quadro.canvasFalhou or 0) + 1
  end

  -- O LAÇO DE EVENTOS RODA FORA DO CANVAS, e é isso que deixa a lista de
  -- faixas acionar controles.
  --
  -- Ele morava dentro do `if` do canvas, então com o painel escondido
  -- (modo "inteira") nenhum evento era tratado — e é justamente aí que
  -- clicar no nome de uma faixa é a ÚNICA forma de acionar o controle,
  -- porque os botões do .form não estão na tela. Aqui fora, o mesmo laço
  -- serve as duas origens.
  local events = eventosDoForm or {}

  -- SOLTA O QUE ESTAVA SEGURO assim que o botão do mouse sobe.
  --
  -- Aqui fora, e não na linha: a linha pode ter rolado para fora da
  -- tela, as faixas podem ter sido fechadas, a música pode ter trocado.
  -- Um momentâneo que recebe a descida e nunca a subida fica ACESO para
  -- sempre, com a nota MIDI presa — e no palco isso é um refletor que
  -- não apaga.
  if next(faixas.segurando) ~= nil then
    local aindaBaixo = ImGui.IsMouseDown and ImGui.IsMouseDown(ctx, 0)
    if not aindaBaixo then
      for tag in pairs(faixas.segurando) do
        local el = session and session.byTag[tag]
        if el then
          faixas.acionar[#faixas.acionar + 1] =
            { element = el, kind = 'release' }
        end
        faixas.segurando[tag] = nil
      end
    end
  end

  -- OS ACIONAMENTOS VINDOS DA LISTA entram na MESMA fila do .form.
  -- Envio MIDI, preparo automático, gravação e registro são os mesmos;
  -- um caminho paralelo seria um segundo lugar onde a regra pode
  -- divergir do primeiro sem ninguém notar.
  if #faixas.acionar > 0 then
    for _, ev in ipairs(faixas.acionar) do events[#events + 1] = ev end
    faixas.acionar = {}
  end

  -- GRUPOS DE FADER, TAMBÉM PELO ARRASTO — não só a roda (ver
  -- handleFaderGroups, chamado mais cedo no quadro, antes do
  -- Renderer.draw). Enquanto a tecla do grupo estiver segurada,
  -- arrastar QUALQUER fader do grupo arrasta os outros junto: mesmo
  -- modo de cada grupo (diferença ou mesmo valor). A conta em si
  -- (quem pertence a quem, delta ou mesmo valor) é pura e vive em
  -- FaderGroups.dragExtras — aqui só se traduz o resultado em
  -- eventos 'fader' SINTÉTICOS, acrescentados a `events` ANTES do
  -- laço abaixo, pra passar pelo MESMO caminho de envio MIDI e
  -- gravação do evento real, sem duplicar essa lógica aqui.
  if session then
    local arrastosReais = {}
    for _, ev in ipairs(events) do
      if ev.kind == 'fader' and ev.element and ev.element.tag then
        arrastosReais[#arrastosReais + 1] = { tag = ev.element.tag, value = ev.value }
      end
    end

    local extras = FaderGroups.dragExtras(arrastosReais, groupHeldNow, faderGroups,
      function(tag)
        local el = session.byTag[tag]
        return el and Session.faderValue(session, el) or nil
      end)

    for _, extra in ipairs(extras) do
      local el = session.byTag[extra.tag]
      if el then
        events[#events + 1] = { element = el, kind = 'fader', value = extra.value }
      end
    end
  end

  for _, ev in ipairs(events) do
    local e = ev.element
    local intents

    -- Clique direito: abre o menu de atribuição de tecla F1-F12 (ver
    -- drawFKeyMenu) e para por aqui — não é um acionamento do
    -- controle, não manda MIDI nem entra na gravação.
    if ev.kind == 'rightclick' then
      fkeyMenuElement = e
      ImGui.OpenPopup(ctx, 'fkeyMenu')
      goto continua
    end

    if ev.kind == 'press' then
      intents = Session.hold(session, e)
    elseif ev.kind == 'release' then
      intents = Session.release(session, e)
    elseif ev.kind == 'fader' then
      intents = Session.setFader(session, e, ev.value)
      -- Marca como EM MOVIMENTO desde já: o espelho precisa sair da
      -- frente mesmo quando não se está gravando, senão o fader é
      -- puxado de volta pelo valor gravado.
      if e.tag then
        if recording then meus[e.tag] = true end
        -- PARADO, mexer no fader é MARCA, como clicar num botão: é o
        -- que o REC seguinte vai aplicar. Sem isto, posicionar o
        -- cursor, mexer no fader e gravar não mudava nada — o punch-in
        -- nem sabia que ele tinha sido tocado.
        if not Transport.isPlaying() then espelho.marcados[e.tag] = true end
        local mov = faderMov[e.tag]
        if not mov then
          mov = { element = e, pontos = {} }
          faderMov[e.tag] = mov
        end
        mov.tocado = true
        mov.ultimo = reaper.time_precise and reaper.time_precise() or 0
      end
    elseif ev.kind == 'wheel' then
      intents = Session.wheelFader(session, e, ev.notches, ev.fine,
        reaper.time_precise and reaper.time_precise() or nil)
      -- Mesma marca do arrasto direto (ramo 'fader' acima): a roda
      -- também toca o fader, e precisa contar como seu até o Stop.
      -- Sem isto, um fader mexido só pela roda voltaria a pular
      -- sozinho pra programação antiga assim que a roda parasse.
      if recording and e.tag then meus[e.tag] = true end
      if e.tag and not Transport.isPlaying() then
        espelho.marcados[e.tag] = true
      end
    else
      intents = Session.press(session, e)
    end

    -- A janela é a única que fala com a porta MIDI. O Session só diz
    -- o que precisa ser enviado; nunca envia nada por conta própria.
    --
    -- O RESULTADO de cada envio vai para o registro. Sem isso, "o
    -- Lumikit não recebeu" é indistinguível de "o LumiBridge não
    -- mandou", e não há como saber de que lado está o problema.
    for _, intent in ipairs(intents) do
      if intent.action == 'send' then
        local n = MidiOut.sendAll(intent.commands, intent.value)
        if n == 0 then
          log(('  FALHOU o envio de %s: %s'):format(
            e.text or tostring(e.tag),
            MidiOut.lastError or 'motivo desconhecido'))
        end
      elseif intent.action == 'release' then
        MidiOut.releaseAll(intent.commands)
      end
    end

    -- MARCA O QUE VEIO DE CLIQUE SEU, parado, para o REC saber o que
    -- é intenção e o que é só reflexo do que já está gravado.
    --
    -- O espelho acende os botões conforme a programação passa pelo
    -- cursor, e aceso na tela não quer dizer "o usuário pediu". Sem
    -- separar as duas coisas, apertar REC repunha na timeline tudo o
    -- que o espelho tinha acendido — e a regra "apertar REC sem
    -- clicar nada não escreve nenhuma nota" caía por terra.
    -- FADERES TAMBÉM CONTAM COMO MARCA.
    --
    -- Só os botões entravam aqui, e o resultado foi o relatado:
    -- posicionar o cursor, mexer num fader e gravar não mudava nada —
    -- o punch-in nem sabia que o fader tinha sido tocado. Mover um
    -- fader parado é a mesma intenção que clicar num botão parado.
    if not Transport.isPlaying() then
      for _, intent in ipairs(intents) do
        if intent.action == 'state' and intent.element
           and intent.element.tag then
          espelho.marcados[intent.element.tag] = intent.on or nil
        end
      end
    end

    -- GRAVAÇÃO. Precisa acontecer aqui, no mesmo lugar em que os
    -- eventos são tratados: é o único ponto que conhece as intenções
    -- de estado que o Session produziu.
    if recording and recorder and Timeline.isReady() then
      local rctx = context()

      -- Observa os cliques normais para estimar a latência sozinho.
      -- Você tende a clicar perto das batidas; se os cliques ficam
      -- sistematicamente atrasados na mesma medida, isso é a sua
      -- latência, e não é preciso parar para calibrar.
      if autoOn and rctx.playing and ev.kind ~= 'fader'
         and ev.kind ~= 'wheel' then
        autoCal = autoCal or Calibration.new()
        -- Sem a compensação aplicada: queremos medir o atraso CRU.
        local raw = Timeline.context(0)
        local spq = Timeline.qnToTime(1) - Timeline.qnToTime(0)
        Calibration.observe(autoCal, raw.qn, spq)
      end
      if ev.kind == 'fader' or ev.kind == 'wheel' then
        -- COLETA as leituras do movimento. Elas vão todas para o
        -- Lumikit (a luz acompanha o gesto) e, de vez em quando
        -- (liveWriteFader), um rascunho vai para a timeline também —
        -- só pra você ver o traço crescendo. A forma FINAL, gravada
        -- de verdade, só sai quando o arrasto termina: aí Curve.polish
        -- simplifica tudo e substitui o rascunho (ver o fechamento do
        -- gesto, mais abaixo).
        for _, intent in ipairs(intents) do
          if intent.faderValue then
            local mov = faderMov[e.tag]
            if not mov then
              mov = { element = e, pontos = {} }
              faderMov[e.tag] = mov
            end
            mov.pontos[#mov.pontos + 1] =
              { qn = rctx.qn, value = intent.faderValue }
            mov.ultimo = reaper.time_precise and reaper.time_precise() or 0
            liveWriteFader(mov, rctx, intent.faderValue)
          end
        end
      else
        record(intents, rctx)
      end
    end

    if ev.kind ~= 'fader' and ev.kind ~= 'wheel' then
      local cmd = e.commands and e.commands[1]
      state.lastAction = ('%s em %s (tag=%s)')
        :format(ev.kind, e.text or '(sem nome)', tostring(e.tag))

      local routed
      if not cmd then
        routed = 'sem mapeamento MIDI'
      elseif MidiOut.isReady() then
        routed = ('-> %s'):format(MidiOut.deviceName)
      elseif not MidiOut.enabled then
        routed = '(envio desligado)'
      else
        routed = '(nenhuma porta selecionada)'
      end

      -- Inclui os BYTES realmente entregues e o total acumulado: é o
      -- que permite comparar o que saiu daqui com o que o Lumikit
      -- recebeu, em vez de discutir no escuro.
      local ultima = MidiOut.lastMessage
      -- Passa a ser SEU até o fim da gravação.
      if recording and e.tag then meus[e.tag] = true end

      log(('clique %-16s tag=%-4s %-28s %s  [%s | total %d]')
        :format(e.text or '(sem nome)', tostring(e.tag),
                cmd and Model.describeCommand(cmd) or '—', routed,
                ultima and ('%02X %d %d'):format(
                  ultima.status, ultima.data1, ultima.data2) or 'nada',
                MidiOut.sentCount))
    end
    ::continua::
  end

  -- PEDIDO VINDO DO MENU DA FAIXA. Um popup não abre outro de dentro de
  -- si; o pedido atravessa o quadro numa variável e é atendido aqui.
  if faixas.pedirTeclaF then
    fkeyMenuElement = faixas.pedirTeclaF
    faixas.pedirTeclaF = nil
    ImGui.OpenPopup(ctx, 'fkeyMenu')
  end

  -- O MENU DE TECLA F1-F12, aberto pelo clique direito no laço acima.
  -- Fica aqui, e não dentro do canvas, porque OpenPopup e BeginPopup
  -- precisam do mesmo escopo de ID — separados, o menu não abre.
  drawFKeyMenu()


  -- POR ÚLTIMO: desenhado depois do canvas, no mesmo DrawList, para
  -- ficar visualmente por cima dele (ver drawSettingsPanel).
  drawSettingsPanel(painelX, painelY, painelW, painelH)

  -- E A CONFIRMAÇÃO DEPOIS DELE: por cima de tudo, configurações
  -- inclusive. Uma confirmação escondida atrás de algo não confirma nada.
  drawConfirmacao(painelX, painelY, painelW, painelH)

  -- A JANELA MUDOU DE TAMANHO OU DE LUGAR NESTE QUADRO?
  --
  -- Medido no fim do quadro, depois de tudo o que poderia tê-la movido.
  -- Minimizada não conta: ali a janela muda de tamanho de propósito.
  if not chrome.minimizado and ImGui.GetWindowPos and ImGui.GetWindowSize then
    local jx, jy = ImGui.GetWindowPos(ctx)
    local jw, jh = ImGui.GetWindowSize(ctx)
    if geo.x and (jx ~= geo.x or jy ~= geo.y or jw ~= geo.w or jh ~= geo.h) then
      geo.contadas = geo.contadas + 1
      if geo.ditas < 24 then
        geo.ditas = geo.ditas + 1
        log(('janela: %.0fx%.0f em %.0f,%.0f  (era %.0fx%.0f em %.0f,%.0f)')
          :format(jw, jh, jx, jy, geo.w, geo.h, geo.x, geo.y))
      end
    end
    -- LEMBRA O TAMANHO E O LUGAR entre sessões.
    --
    -- Só quando NÃO está maximizada nem minimizada: nesses dois estados
    -- a geometria é do estado, não da escolha de quem arrastou a borda —
    -- guardar 54x42 da pastilha faria a janela reabrir do tamanho dela.
    --
    -- E não a cada quadro: gravar ExtState sessenta vezes por segundo é
    -- trabalho por nada. Meio segundo depois da última mudança já é
    -- instantâneo para quem arrasta e raro para o disco.
    if not maxi.on and jw > 200 and jh > 150 then
      if jx ~= geo.salvoX or jy ~= geo.salvoY
         or jw ~= geo.salvoW or jh ~= geo.salvoH then
        geo.salvarEm = (reaper.time_precise and reaper.time_precise() or 0) + 0.5
        geo.salvoX, geo.salvoY, geo.salvoW, geo.salvoH = jx, jy, jw, jh
      elseif geo.salvarEm
             and (reaper.time_precise and reaper.time_precise() or 0) >= geo.salvarEm then
        geo.salvarEm = nil
        reaper.SetExtState(EXT_SECTION, 'janela',
          ('%d %d %d %d'):format(jx, jy, jw, jh), true)
      end
    end

    geo.x, geo.y, geo.w, geo.h = jx, jy, jw, jh
  end
end

-- ------------------------------------------------------------- laço

local function loop()
  local tTotal = cronometro()
  -- Mede o intervalo REAL entre quadros. O script roda a ~30 fps, mas a
  -- taxa varia com a carga da máquina — supor um valor fixo deixaria um
  -- viés que muda de projeto para projeto.
  if reaper.time_precise then
    local now = reaper.time_precise()
    if quadro.ultimoEm then
      local dt = now - quadro.ultimoEm
      -- Média móvel, e ignora picos: uma travada de meio segundo não
      -- pode virar meio segundo de compensação.
      if dt > 0 and dt < 0.2 then
        quadro.media = quadro.media * 0.9 + dt * 0.1
      end

      -- O PIOR INTERVALO, ao lado da média — e SEM o filtro dela.
      --
      -- A média descarta dt acima de 200 ms, e está certa em descartar:
      -- ela alimenta a compensação de clique, e uma travada de meio
      -- segundo não pode virar meio segundo de compensação. Só que é
      -- exatamente o que ela descarta que o olho vê. Sem esta medida,
      -- uma tela que trava e salta aparece no diagnóstico como 29
      -- quadros por segundo, saudáveis — foi o que o registro do usuário
      -- mostrou enquanto a tela pulava na frente dele.
      --
      -- E o tempo GASTO por quadro não responde isso: gastar 11 ms não
      -- impede o quadro seguinte de chegar 300 ms depois. Um mede o
      -- nosso trabalho, o outro mede o que a tela mostra.
      if dt > (pico.atual.intervalo or 0) then pico.atual.intervalo = dt end
      if dt > 0.1 then quadro.travadas = (quadro.travadas or 0) + 1 end
    end
    quadro.ultimoEm = now
    -- Na média, o clique aconteceu meio quadro antes de ser detectado.
    Timeline.frameCompensation =
      math.min(quadro.media * 0.5, Timeline.MAX_FRAME_COMPENSATION)
  end

  -- O TAMANHO E O LUGAR DA ÚLTIMA VEZ, se houver.
  --
  -- 1200x800 é um chute razoável para a primeira abertura e um estorvo
  -- em todas as seguintes: quem ajusta a janela ao seu monitor espera
  -- reencontrá-la assim.
  --
  -- "SEMPRE", E NÃO "SÓ NA ESTREIA" — dentro de um bloco que roda UMA
  -- VEZ, que dá no mesmo e funciona.
  --
  -- FirstUseEver quer dizer "a menos que o ImGui já tenha um tamanho
  -- guardado para esta janela". E ele guarda: o ReaImGui mantém um ini
  -- próprio, indexado pelo NOME da janela. Ou seja, a geometria que nós
  -- salvávamos com tanto cuidado nunca era aplicada — quem mandava era o
  -- ini dele, com o último tamanho que a janela teve. Como a pastilha
  -- encolhe a janela de verdade, bastava tê-la minimizado uma vez para
  -- ela reabrir minúscula para sempre, num canto.
  --
  -- Com Cond_Always aqui, o nosso valor vale no primeiro quadro e nunca
  -- mais: redimensionar continua livre depois disso.
  if not geo.restaurada then
    geo.restaurada = true
    local sempre = Compat.const(ImGui, 'Cond_Always', 1)
    local salvo = reaper.GetExtState(EXT_SECTION, 'janela')
    local jx, jy, jw, jh = salvo:match('^(-?%d+) (-?%d+) (%d+) (%d+)$')
    if jw and tonumber(jw) > 200 and tonumber(jh) > 150 then
      ImGui.SetNextWindowSize(ctx, tonumber(jw), tonumber(jh), sempre)
      if ImGui.SetNextWindowPos then
        pcall(ImGui.SetNextWindowPos, ctx, tonumber(jx), tonumber(jy), sempre)
      end
    else
      ImGui.SetNextWindowSize(ctx, 1200, 800, sempre)
    end
  end

  -- SEM LICENÇA, A JANELA ABRE NUM TAMANHO QUE DÁ PARA LER.
  --
  -- DEPOIS da restauração acima, e não antes: quem chama
  -- SetNextWindowSize por último é quem manda, e posto antes eu era
  -- desfeito pela linha do FirstUseEver logo em seguida. O teste apanhou
  -- — ele pergunta qual foi o ÚLTIMO tamanho pedido.
  --
  -- O ReaImGui guarda o tamanho de cada janela pelo NOME dela, no ini
  -- dele, e não no nosso ExtState. FirstUseEver só vale enquanto não
  -- houver nada guardado ali: uma janela que um dia ficou pequena (a
  -- pastilha encolhe a janela de verdade) reabre pequena para sempre.
  --
  -- Na tela de ativação isso é intolerável — é a primeira coisa que o
  -- cliente vê do que acabou de comprar, e a primeira instalação de
  -- verdade abriu encolhida num canto, com o dono tendo de caçá-la e
  -- esticá-la para conseguir ativar. Aqui o tamanho é imposto, e a
  -- pastilha fica desligada: minimizado sem ter como ativar seria uma
  -- armadilha.
  if not chrome.lic.ativa then
    chrome.minimizado = false
    ImGui.SetNextWindowSize(ctx, 880, 620, Compat.const(ImGui, 'Cond_Always', 1))
  end

  -- Sem isto, clicar no REAPER esconde o LumiBridge atrás dele e você
  -- precisa alternar de janela a cada ajuste. Programar iluminação é
  -- justamente ficar indo e voltando entre os dois.
  --
  -- SEMPRE FLUTUANTE, nunca acoplada. Havia um botão "Encaixar" (removido
  -- a pedido do usuário) que docava a janela no REAPER; o problema é que
  -- uma janela acoplada se fecha pelo controle de DOCK do REAPER, não
  -- pelo X do ImGui — e o laço abaixo (`if open then reaper.defer(loop)
  -- end`) só percebe o fechamento pelo X. Docada, fechar pelo dock podia
  -- deixar o script rodando escondido, sem janela nenhuma visível. Sem
  -- dock, o X sempre é o X: fechar por ele encerra o script de verdade.
  if ImGui.SetNextWindowDockID then
    pcall(ImGui.SetNextWindowDockID, ctx, 0)
  end

  -- SEM a barra de título do ImGui: a nossa é desenhada dentro do quadro
  -- (ver drawBarraTitulo). Com ela vinham o X genérico e o triângulo de
  -- "collapse", que escondia tudo menos a própria barra — no lugar dele
  -- há o botão de minimizar, que esconde a janela de verdade.
  -- A JANELA PRINCIPAL NÃO ROLA. Nunca.
  --
  -- "Em qualquer lugar da tela a roleta funciona e buga a tela, como se
  -- quisesse rodar toda tela pra cima e pra baixo." Era isso, e era a
  -- causa do pulo — não o desenho, não a escala, não a moldura.
  --
  -- Esta janela é um painel, não um documento: o .form encaixa no espaço
  -- que tem, as faixas rolam por conta própria, e as configurações e o
  -- registro são filhas com rolagem própria. A janela em volta não tem
  -- para onde rolar, e não deveria nem ter permissão.
  --
  -- Bastava um item terminar UM PIXEL depois da borda de baixo — a
  -- divisória vertical, a coluna das faixas, qualquer coisa desenhada em
  -- posição absoluta — para o conteúdo passar a ser maior que a janela.
  -- Aí aparece a barra, a barra come largura, o encaixe muda, o conteúdo
  -- muda, a barra some. E, de quebra, a roda do mouse passava a arrastar
  -- a tela inteira em vez de rolar a lista de faixas.
  --
  -- Só acontecia no modo "ao lado" porque é o único em que se desenha em
  -- posição absoluta até a borda de baixo.
  local nomes = {
    'WindowFlags_NoTitleBar',
    'WindowFlags_NoScrollbar',
    'WindowFlags_NoScrollWithMouse',
  }
  -- MINIMIZADA, sempre por cima — mesmo com "Sempre visível" desligado.
  -- Uma pastilha de 54px que escorregasse pra trás do REAPER seria
  -- exatamente o problema que ela existe pra resolver: uma janela que
  -- some e não se acha mais.
  if chrome.aoAlto or chrome.minimizado then
    nomes[#nomes + 1] = 'WindowFlags_TopMost'
  end
  -- Minimizada não se redimensiona pelo canto: o tamanho é o da
  -- pastilha, e arrastar a borda dela só produziria um retângulo torto.
  if chrome.minimizado then nomes[#nomes + 1] = 'WindowFlags_NoResize' end
  local flags = Compat.windowFlags(ImGui, nomes)

  -- Maximizada, sem cantos redondos: eles deixariam o desktop
  -- aparecer por quatro buracos nas pontas da tela.
  local nCores, nVars = Theme.push(ImGui, ctx, Compat, maxi.on)
  local visible, open = ImGui.Begin(ctx, 'LumiBridge', true, flags)

  local ok, err = true, nil
  if visible then
    -- xpcall com traceback: sem a pilha, um erro de API vira adivinhação.
    ok, err = xpcall(frame, function(e)
      return tostring(e) .. '\n\n' .. debug.traceback('', 2)
    end)
    ImGui.End(ctx)
  end

  -- O estilo precisa ser desempilhado SEMPRE, inclusive quando o quadro
  -- falha: deixar cores empilhadas corromperia os quadros seguintes.
  Theme.pop(ImGui, ctx, nCores, nVars)

  -- Um erro de API dentro do quadro se repetiria a 60 quadros por
  -- segundo. Relatamos uma vez, com contexto, e encerramos o laço.
  if not ok then
    local context = ''
    if state.lastAction then
      context = '\n\nÚltima ação: ' .. state.lastAction
    end
    reaper.ShowConsoleMsg('[LumiBridge] erro no quadro:\n' .. tostring(err)
      .. context .. '')
    reaper.MB(tostring(err) .. context ..
      '\n\nO LumiBridge foi encerrado para não repetir o erro.'
      .. '\nO texto acima também está no console (View > ReaScript console).',
      'LumiBridge', 0)
    return
  end

  -- O painel de configurações agora é desenhado DENTRO de `frame` (por
  -- cima do canvas, na mesma janela) — já coberto pelo xpcall acima,
  -- não precisa de um segundo aqui.

  medir('total', tTotal)

  -- Fecha a janela de medição a cada três segundos.
  do
    local agoraPico = cronometro()
    if agoraPico >= pico.ate then
      if pico.ate > 0 then pico.ultimo = pico.atual end
      pico.atual = {}
      pico.ate = agoraPico + 3.0
    end
  end

  -- SINAL DE VIDA + PEDIDO DE RESTAURAÇÃO.
  --
  -- O carimbo diz "existe uma instância rodando agora" — é o que faz a
  -- segunda execução da ação se recusar a abrir uma janela nova (ver
  -- Window.start). E é justamente por ela pedir restauração em vez de
  -- abrir que uma janela minimizada nunca fica inalcançável, mesmo que
  -- o Windows não lhe dê botão na barra de tarefas.
  --
  -- Escrito com persist = false: é estado de execução, não preferência,
  -- e não faz sentido sobreviver ao fechamento do REAPER.
  reaper.SetExtState(EXT_SECTION, 'vivo_em', tostring(os.time()), false)

  -- A ação foi executada com o LumiBridge já aberto: em vez de uma
  -- segunda janela, desminimiza (se estiver) e pula pra frente.
  if reaper.GetExtState(EXT_SECTION, 'restaurar') == '1' then
    reaper.DeleteExtState(EXT_SECTION, 'restaurar', false)
    if chrome.minimizado then
      chrome.minimizado = false
      chrome.restaurando = 2
      chrome.pendW, chrome.pendH = chrome.normalW, chrome.normalH
      encaixe.w = 0
    end
    trazerParaFrente()
  end

  -- Sem a barra do ImGui não há X dele, então `open` nunca vira false
  -- por conta própria: quem encerra é o nosso botão (ver
  -- drawBarraTitulo), pelo chrome.fechar.
  if open and not chrome.fechar then
    reaper.defer(loop)
  else
    -- Some o sinal de vida: sem isto, a próxima execução da ação veria
    -- um carimbo recente e se recusaria a abrir, por até dois segundos.
    reaper.DeleteExtState(EXT_SECTION, 'vivo_em', false)
  end
end

-- Ganchos de teste. Existem para que tests/test_window_record.lua possa
-- ligar a gravação e inspecionar o estado sem abrir o REAPER. Foi a
-- ausência de um teste assim que deixou passar uma record() órfã, nunca
-- chamada pelo laço de quadros.
function Window.__setRecording(v) recording = v end
function Window.__setAdvanced(v) painel.aberto = v end
function Window.__setAba(v) abaAtual = v end
--- Estado da licença, para o teste. `__lerLicenca` refaz a leitura como
--  no início do programa; `__licencaAtiva` diz se a janela vai abrir.
function Window.__lerLicenca() return chrome.lerLicenca() end
function Window.__licencaAtiva() return chrome.lic.ativa end
function Window.__codigoDaMaquina() return chrome.lic.codigo end
function Window.__digitarChave(v) chrome.lic.digitada = v end
function Window.__setMinimizado(v) chrome.minimizado = v end
--- O assistente de primeiros ajustes, para os testes.
--  Sem argumento, só conta o estado.
function Window.__assistente(abrir, passo)
  if abrir ~= nil then
    painel.assist.aberto = abrir
    painel.assist.passo  = passo or 1
    painel.assist.recado = nil
  end
  return painel.assist.aberto, painel.assist.passo
end

--- Simula uma leitura de gesto de fader, como o arrasto faz.
--  Existe para tests/test_window_record.lua poder parar a gravação com
--  um gesto PENDENTE e provar que ele não se perde.
function Window.__gestoFader(tag, valor)
  local e = session and session.byTag[tag]
  if not e then return false end
  local mov = faderMov[tag]
  if not mov then
    mov = { element = e, pontos = {} }
    faderMov[tag] = mov
  end
  local rc = context()
  mov.pontos[#mov.pontos + 1] = { qn = rc.qn, value = valor }
  mov.ultimo = reaper.time_precise and reaper.time_precise() or 0
  return true
end
--- Salta o cursor como se a timeline tivesse sido clicada e solta.
--  Existe para tests/test_window_record.lua provar que saltar DURANTE a
--  gravação fecha as linhas onde estavam e as reabre no destino, em vez
--  de esticar as notas por cima do trecho pulado.
function Window.__saltarPara(seg) saltarPara(seg, false) end
function Window.__zoom() return state.zoom end
function Window.__fontMode() return state.fonts and state.fonts.mode end
function Window.__hasLayout() return layout ~= nil end
function Window.__setAutoZoom(v) opcoes.zoom = v; state.zoom = 1.0 end
function Window.__setVerbose(v) painel.verbose = v; painel.linhas = {} end
function Window.__clearLog() painel.linhas = {} end
function Window.__logText() return logText() end
function Window.__logCount() return #painel.linhas end

--- Programa notas de várias cores, para os testes terem o que atravessar.
function Window.__preencher()
  if not session or not Timeline.isReady() then return end
  local cores = {}
  for _, e in ipairs(layout.elements) do
    if e.rivalPitches and e.commands and e.commands[1] then
      cores[#cores + 1] = e
      if #cores >= 4 then break end
    end
  end
  local escritas = {}
  for i, e in ipairs(cores) do
    escritas[#escritas + 1] = {
      kind = 'note', channel = e.commands[1].channel,
      pitch = e.commands[1].data1, velocity = 127,
      startQN = (i - 1) * 20, endQN = i * 20,
    }
  end
  Timeline.write(escritas)
end
function Window.__startRecording() startRecording() end
function Window.__stopRecording() stopRecording() end
function Window.__isRecording() return recording end
--- Marca um botão como aceso, sem clique. Usado só nos testes.
function Window.__setArmed(n)
  if not session then return end
  local i = 0
  for _, e in ipairs(layout.elements) do
    if e.tag and e.commands and #e.commands > 0
       and not session.faderTags[e.tag] then
      i = i + 1
      if i <= n then session.active[e.tag] = true end
    end
  end
end

function Window.__clearState()
  espelho.marcados = {}
  if session then
    for tag in pairs(session.active) do session.active[tag] = false end
  end
end

function Window.__openLines()
  return recorder and Recorder.openCount(recorder) or 0
end

function Window.__regionName() return region and region.name end
function Window.__faixasAbertas() return faixas.abertas end
function Window.__faixasInteira() return faixas.inteira end
function Window.__faixasFaders()
  local n = 0
  for _, l in ipairs(faixas.linhas) do
    if l.tipo == 'fader' then n = n + 1 end
  end
  return n
end
function Window.__faixasTodos() return faixas.todos end
function Window.__faixasLado() return faixas.lado end
function Window.__faixasRolagem() return faixas.rolagem end
function Window.__faixasRemontagens() return faixas.remontagens or 0 end
function Window.__zoomMudou() return encaixe.mudou or 0 end
function Window.__pico() return pico.ultimo or {} end
function Window.__geoMudou() return geo.contadas or 0 end
--- Geometria do miolo das faixas: onde o corpo começa e quanto mede a
--  coluna de nomes. Existe para o teste conferir que nada é submetido
--  acima do corpo — o cabeçalho fica logo ali em cima.
function Window.__faixasGeom()
  local g = faixas.geom or {}
  return g.yc or 0, g.gutter or 0, g.corpo or 0, g.x0 or 0
end

--- Um X dentro da coluna de nomes, no quadro desenhado.
--
--  Os testes escreviam 40 na mão, de quando o simulador jurava que a
--  origem da tela era zero. Deixando de jurar, quarenta virou um ponto
--  fora do painel — e o gesto testado passava a não acontecer, sem que a
--  verificação soubesse dizer isso.
function Window.__xDoNome(fracao)
  local g = faixas.geom or {}
  return math.floor((g.x0 or 0) + (g.gutter or 0) * (fracao or 0.3))
end

--- Valor 0..1 de um fader, pela tag. Para o teste conferir que o gesto
--  na lista chegou ao mesmo lugar que o gesto no .form chegaria.
--- Define um grupo de faders, como faz a aba Grupos. Existe para o teste
--  poder provar que o gesto na LISTA arrasta os companheiros igual ao
--  gesto no .form — a alternativa seria confiar em que os dois passam
--  pela mesma fila, que é justamente o que precisa ser verificado.
function Window.__definirGrupoFader(num, modo, tags)
  faderGroups[num] = { mode = modo, tags = tags, ativo = true }
end
function Window.__setDicas(v) opcoes.dicas = v end
function Window.__setAtraso(seg) latency = seg end
function Window.__margemBarra() return M.margem end
--- A folga entre os quatro blocos da barra, no último quadro desenhado.
function Window.__respiroBarra() return encaixe.respiro or 0 end
--- O vão que sobrou antes do último bloco da barra. É o que denuncia a
--  repartição errada: com as quatro partes ajustadas ele é igual à
--  folga; presa a folga no mínimo, ele é que engorda sozinho.
function Window.__sobraBarra() return encaixe.barraSobra end
--- O que a barra CONTOU que os blocos 1 a 3 ocupam, e o que ela MEDIU
--  percorrendo a linha. Os dois têm de bater: se a contagem se descolar
--  do desenho — um item novo que ninguém somou —, é aqui que aparece.
function Window.__conteudoBarra() return encaixe.barraConteudo end
function Window.__usadoBarra() return encaixe.barraUsado end
--- Liga ou desliga um dos ajustes da barra e do acompanhamento. Existe
--  porque agora há controles que só aparecem quando o ajuste está
--  ligado: sem isto, um teste não teria como chegar a eles.
function Window.__setOpcao(nome, valor) opcoes[nome] = valor end
function Window.__opcao(nome) return opcoes[nome] end
function Window.__gutter() return faixas.gutter end
function Window.__setGutter(v) faixas.gutter = v; faixas.salvarEm = 0 end
function Window.__ocultos() return faixas.nomesOcultos or {} end
function Window.__painelAberto() return painel.aberto end
--- Quantos pontos de CC estão selecionados, no total.
function Window.__selCC()
  local n = 0
  for _, tempos in pairs(faixas.selCC or {}) do
    for _ in pairs(tempos) do n = n + 1 end
  end
  return n
end
--- Quantas notas estão na seleção múltipla.
function Window.__selNotas()
  local n = 0
  for _, inicios in pairs(faixas.selNotas or {}) do
    for _ in pairs(inicios) do n = n + 1 end
  end
  return n
end
function Window.__canalDaLinha(i)
  local l = faixas.linhas[i]
  return l and l.canal
end
function Window.__setSeguir(v) faixas.seguirCursor = v end
function Window.__setVista(de, ate) faixas.vDe, faixas.vAte = de, ate end
function Window.__posicaoDeEscrita() return posicaoDeEscrita() end
function Window.__valorFader(tag)
  local el = session and session.byTag[tag]
  if not el then return nil end
  return Session.faderValue(session, el)
end
function Window.__faixasDesenho()
  return faixas.desenhadas or 0, faixas.segmentos or 0
end

--- Pede uma remontagem imediata, como fazem os `faixas.at = 0`
--  espalhados pelo arquivo (trocar de música, mudar a cor de uma faixa,
--  ligar "todos"). Existe para o teste poder exercitar ESSE caminho: a
--  assinatura sozinha não cobre o que não passa por ela.
function Window.__pedirRemontagem() faixas.at = 0 end

--- Quem está aceso agora, por tag, em ordem. Existe para comparar o
--  resultado de um acionamento vindo do .form com o mesmo acionamento
--  vindo da lista de faixas: "igual" tem de ser verificável, não
--  prometido.
function Window.__ativos()
  local t = {}
  if session then
    for tag, on in pairs(session.active) do
      if on and not session.faderTags[tag] then t[#t + 1] = tag end
    end
  end
  table.sort(t)
  return t
end
function Window.__ultimaAcao() return state.lastAction end
function Window.__limparAcao() state.lastAction = nil end
function Window.__faixasSemCC() return faixas.semCC end
function Window.__confirmando() return confirmar ~= nil end
function Window.__layoutInfo()
  return { w = layout and layout.contentWidth or 0,
           h = layout and layout.contentHeight or 0,
           mx = layout and layout.marginX or 0,
           my = layout and layout.marginY or 0 }
end
function Window.__vista() return vistaDaMusica() end

--- Ponto na tela do centro da linha `i` no instante `t`.
--  Usa a geometria do último quadro desenhado, para o teste clicar
--  exatamente onde o usuário clicaria.
function Window.__faixasPonto(i, t)
  local g = faixas.geom
  if not g or not g.alturas[i] then return nil end
  local y = g.yc - faixas.rolagem
  for k = 1, i - 1 do y = y + g.alturas[k] end
  local frac = (t - g.de) / g.duracao
  return g.x0 + g.gutter + frac * g.areaW, y + g.alturas[i] * 0.5
end

--- Descreve as linhas para o teste escolher onde clicar.
function Window.__faixasInfo()
  local out = {}
  for i, l in ipairs(faixas.linhas) do
    local b = l.blocos[1]
    out[i] = { nome = l.nome, tipo = l.tipo, pitch = l.pitch, tag = l.tag,
               ligado = l.ligado or false,
               momentaneo = l.momentaneo or false,
               blocos = #l.blocos,
               t0 = b and b.t0, t1 = b and b.t1,
               fecho = b and b.fecho ~= nil or false,
               fechoT0 = b and b.fecho and b.fecho.t0 }
  end
  return out
end
function Window.__escalaV() return faixas.escalaV or 1 end
function Window.__faixasLinhas() return #faixas.linhas end

--- Marca um fader como TOCADO PELO USUÁRIO com o cursor parado.
--  É o que o arrasto e a roda fazem; aqui é a mesma marca, sem depender
--  de acertar o pixel do fader no simulador.
function Window.__marcarFader(tag) espelho.marcados[tag] = true end

--- Põe um fader numa posição, como se tivesse sido arrastado até ali.
function Window.__posicionarFader(tag, valor)
  if session then session.faders[tag] = valor end
end

--- Ajusta as opções de preparo, como a aba Configurações > Preparo.
function Window.__setPreparo(o)
  if o.auto    ~= nil then preparo.auto     = o.auto    end
  if o.release ~= nil then preparo.release  = o.release end
  if o.faders  ~= nil then preparo.faders   = o.faders  end
  if o.cem     ~= nil then preparo.cem = o.cem     end
end

--- Quantos BOTÕES estão acesos na tela agora.
--
--  É por aqui que se verifica o espelho: acender é o efeito visível
--  dele, e é o que o usuário enxerga.
--
--  FADERES FICAM DE FORA, e não por conveniência: um fader em 100% está
--  ativo o tempo todo e nunca "apaga" ao sair de um trecho gravado —
--  contá-lo junto misturaria duas coisas que se comportam de formas
--  opostas. O que se quer medir aqui é o botão que acende e apaga
--  conforme a programação passa.
function Window.__activeCount()
  if not session then return 0 end
  local n = 0
  for tag, ligado in pairs(session.active) do
    if ligado and not session.faderTags[tag] then n = n + 1 end
  end
  return n
end

--- Ponto de entrada da interface.
function Window.start()
  -- INSTÂNCIA ÚNICA — e é isto que torna o minimizar seguro.
  --
  -- Uma janela do ReaImGui minimizada pode não ganhar botão na barra de
  -- tarefas do Windows: minimizada sem botão, não haveria como trazê-la
  -- de volta, e o script ficaria rodando escondido pra sempre. Com o
  -- que está aqui, rodar a AÇÃO DE NOVO é o caminho de volta garantido:
  -- a segunda execução vê que já existe uma instância viva, pede a
  -- restauração por ExtState e sai sem abrir uma segunda janela.
  --
  -- O sinal de vida é um carimbo de tempo reescrito a cada quadro (ver
  -- `loop`). Se o REAPER tiver sido fechado no tacape, ou o script tiver
  -- morrido num erro, o carimbo para de ser atualizado e envelhece: mais
  -- de 2 segundos parado significa que não há mais ninguém do outro
  -- lado, e a execução nova segue normalmente em vez de se recusar a
  -- abrir por causa de um resquício.
  local carimbo = tonumber(reaper.GetExtState(EXT_SECTION, 'vivo_em')) or 0
  if os.time() - carimbo < 2 then
    reaper.SetExtState(EXT_SECTION, 'restaurar', '1', false)
    return
  end

  local im, err = Compat.load()
  if not im then
    reaper.MB(err, 'LumiBridge', 0)
    return
  end
  ImGui = im

  ctx = ImGui.CreateContext('LumiBridge')
  COND_FIRST_USE = Compat.const(ImGui, 'Cond_FirstUseEver', 4)

  -- A LICENÇA, antes de qualquer outra coisa lida.
  chrome.lerLicenca()

  -- Preferência de tela lembrada entre sessões: quem trabalha com o
  -- avançado aberto não deve ter de reabri-lo toda vez.
  painel.aberto = reaper.GetExtState(EXT_SECTION, 'painel.aberto') == '1'

  -- Detalhado NÃO é lembrado, de propósito: sempre começa desligado.
  -- `local painel.verbose = false`, lá em cima, já cobre isso — sem ler o
  -- ExtState aqui.

  -- Limpa um resquício de versões antigas: havia uma preferência de
  -- janela ACOPLADA (removida — ver o comentário sobre SetNextWindowDockID
  -- no laço principal). Sem esta limpeza, quem chegou a acoplar a janela
  -- antes dessa remoção teria o valor '1' preso pra sempre no ExtState,
  -- sem utilidade nenhuma, mas também sem motivo pra deixar sujeira.
  if reaper.GetExtState(EXT_SECTION, 'docked') ~= '' then
    reaper.DeleteExtState(EXT_SECTION, 'docked', true)
  end

  local rota = reaper.GetExtState(EXT_SECTION, 'route')
  if rota == 'track' or rota == 'porta' then MidiOut.route = rota end

  local passo = tonumber(reaper.GetExtState(EXT_SECTION, 'wheel_step'))
  if passo and passo > 0 and passo <= 1 then Session.WHEEL_STEP = passo end

  -- PREPARO — todas ligadas por padrão, que é como o LumiBridge sempre
  -- se comportou. Quem nunca abriu a aba não sente diferença nenhuma.
  --
  -- Lidas por "existe a chave?", não por "vale 1?": estas nascem
  -- VERDADEIRAS, e comparar direto com '1' transformaria "nunca mexi
  -- nisso" (chave vazia) em "desligado" e mudaria o comportamento de
  -- todo mundo na atualização.
  local function lerLiga(chave, atual)
    local v = reaper.GetExtState(EXT_SECTION, chave)
    if v == '' then return atual end
    return v == '1'
  end
  preparo.auto     = lerLiga('prep_auto',      preparo.auto)
  preparo.release  = lerLiga('prep_release',   preparo.release)
  preparo.faders   = lerLiga('prep_faders',    preparo.faders)
  preparo.cem = lerLiga('prep_fader_cem', preparo.cem)

  -- O zoom automático não é mais desligável (removido o checkbox
  -- "Auto"): não lemos mais um '0' salvo de uma versão anterior, senão
  -- alguém que já tinha desligado ficaria travado sem jeito de religar.

  faixas.lado = reaper.GetExtState(EXT_SECTION, 'faixas_lado') == '1'
  opcoes.dicas = reaper.GetExtState(EXT_SECTION, 'dicas') ~= '0'
  faixas.seguirCursor = reaper.GetExtState(EXT_SECTION, 'seguir_cursor') ~= '0'
  opcoes.regioes = reaper.GetExtState(EXT_SECTION, 'op_regioes') == '1'
  opcoes.relogio = reaper.GetExtState(EXT_SECTION, 'op_relogio') == '1'
  opcoes.repetir = reaper.GetExtState(EXT_SECTION, 'op_repetir') ~= '0'
  opcoes.zoomNoMouse = reaper.GetExtState(EXT_SECTION, 'op_zoom_mouse') == '1'
  opcoes.ima = reaper.GetExtState(EXT_SECTION, 'op_ima') ~= '0'

  do
    local medidas = reaper.GetExtState(EXT_SECTION, 'faixas_medidas')
    local g, l, a = medidas:match('^(%d+) (%d+) (%d+)$')
    if g then
      faixas.gutter  = math.max(60, math.min(360, tonumber(g)))
      faixas.largura = (tonumber(l) > 0) and tonumber(l) or nil
      faixas.altura  = math.max(40, tonumber(a))
    end
  end

  local aba = reaper.GetExtState(EXT_SECTION, 'aba')
  if aba ~= '' then abaAtual = aba end

  -- Track da forma de onda: escolha do usuário, lembrada entre sessões.
  waveTrack = reaper.GetExtState(EXT_SECTION, 'wave_track')
  Waveform.setTrack(waveTrack)

  -- Sem track escolhida, tenta a primeira que tenha áudio: é o que o
  -- usuário quase sempre quer, e evita abrir com a timeline vazia.
  if waveTrack == '' then
    local candidatas = Timeline.listTracks()
    for _, t in ipairs(candidatas) do
      if Waveform.hasAudio(t.index) then
        waveTrack = t.name
        Waveform.setTrack(t.name, t.index)
        break
      end
    end
  end

  restoreDevice()
  restoreTrack()
  state.fonts = Theme.createFonts(ImGui, ctx)

  -- NA PRIMEIRA ABERTURA, o assistente na frente.
  --
  -- Depois de restoreDevice/restoreTrack de propósito: quem já tinha
  -- tudo configurado antes desta versão não merece um assistente na
  -- cara — a marca ainda não existe na máquina dele, mas as respostas
  -- sim, e o assistente abre no passo que falta.
  -- E SÓ SE FALTAR ALGUMA COISA. Quem já usava o programa antes desta
  -- versão não tem a marca na máquina, mas tem as respostas — abrir um
  -- assistente na cara dele seria trocar um problema por outro.
  if reaper.GetExtState(EXT_SECTION, 'assistente_visto') ~= '1'
     and not painel.assistOk(painel.ASSIST_TOTAL) then
    painel.assist.aberto = true
    for n = 1, painel.ASSIST_TOTAL do
      if not painel.assistOk(n) then painel.assist.passo = n break end
      painel.assist.passo = painel.ASSIST_TOTAL
    end
    refreshDevices()
  end

  -- Reabre o último arquivo usado, se ainda existir.
  local last = reaper.GetExtState(EXT_SECTION, EXT_LASTFILE)
  if last and last ~= '' then
    local f = io.open(last, 'rb')
    if f then f:close() loadForm(last) end
  end

  reaper.defer(loop)
end

return Window
]=], "@ui/window.lua"))(...)
end

-- ============================ ponto de entrada

local ok, err = pcall(function()
  require('ui.window').start()
end)

if not ok then
  reaper.ShowConsoleMsg('[LumiBridge] erro fatal:\n' .. tostring(err) .. '\n')
  reaper.MB('O LumiBridge encontrou um erro:\n\n' .. tostring(err),
            'LumiBridge', 0)
end
