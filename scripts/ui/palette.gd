class_name Palette

# ---- структура (брутализм-монохром) ----
const BG := Color("08090b")           # самый тёмный фон
const BG_2 := Color("0c0e12")         # промежуточный тёмный
const SURFACE := Color("111317")      # фон панели/модуля
const SURFACE_2 := Color("181b20")    # приподнятый/ховер
const LINE := Color("2b3038")         # рамки/разделители

const BG_DEEP := Color("08090b")      # = BG, алиас для новых модулей
const BG_PANEL := Color("111317")     # = SURFACE
const BG_PANEL_HI := Color("181b20")  # = SURFACE_2
const BORDER := Color("2b3038")       # = LINE
const BORDER_HI := Color("3a4049")    # рамка при ховере/активности

const AMBER := Color("b0833f")        # данные/тёплый — мутный янтарь
const AMBER_DIM := Color("7d5d2d")
const AMBER_SOFT := Color("c2a06a")

const TEXT := Color("cfd3d8")         # основной (тускло-белый)
const TEXT_2 := Color("9aa0a8")       # вторичный
const TEXT_3 := Color("5a626d")       # приглушённый
const TEXT_DIM := Color("717784")     # вторичный (заголовки модулей)
const TEXT_MUTE := Color("454b54")    # выключенный/слабый

const OK := Color("6f9f73")
const WARN := Color("b8923f")
const DANGER := Color("b85a52")
const VOID := Color("7a6f8a")         # пустота — серо-фиолетовый
const ENERGY := Color("6f8b94")       # энергия — серо-бирюзовый
const COMPUTE := Color("7b87a3")      # вычисления — серо-индиго
const CORRUPT := Color("8f4a42")      # красный распада (приглушён)
const SIGNAL := Color("5f8f78")       # зелёный «хорошей» аномалии
const CRYPTO := Color("a89968")       # тускло-золотой акцент крипто-секции
const ENERGY_BRANCH := Color("6f8a6f")   # серо-зелёный — ветка энергии в дереве

# ---- редкость: единственный насыщенный акцент ----
const RARITY_RARE := Color("5a8fbf")     # синее кольцо/свечение редких узлов дерева
const RARITY_LEGENDARY := Color("c9a24a") # золотое кольцо/свечение легендарных узлов дерева

const NODE_BG := Color("0c0f14")         # тёмный «пустой» шар узла дерева
const BLOCKED := Color("d65a5a")         # узел дерева, закрытый взаимоисключающим выбором
