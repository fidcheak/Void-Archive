# PROJECT STATE — Архив Пустоты
Последний слой: L7
Движок: Godot 4.x. Запуск: F5.

## Что уже работает
- Каркас проекта, автозагрузки, дизайн-система (Palette/Theme/CRT).
- Терминальный экран с пульсирующим вращающимся «ядром» по центру.
- Клик по ядру → +1 Данные, счётчик обновляется, терминал пишет строки.
- Игровой цикл (_process, dt-кламп), автосейв каждые ~15с, оффлайн-расчёт по всем накапливаемым ресурсам (production_rates).
- Энергосеть как поток: energy_production/energy_demand/power_ratio пересчитываются каждый тик в Production.recompute(), троттлят производство потребителей энергии. Базовая мощность = BASE_ENERGY + бонусы исследований (add_base_energy).
- Здания: Сканер данных (Данные, ест Энергию), Реактор (Энергия), Суперкомпьютер (Вычисления, ест Энергию). Покупка через Buildings.buy(), цена растёт геометрически.
- Производство обобщено: GameState.production_rates — словарь resource→rate для всех накапливаемых ресурсов (data, compute), учитывает множители исследований (mult_production, mult_building).
- Система исследований (Research): предпосылки, стоимость в Вычислениях, эффекты-множители (`mult_production`, `mult_building`, `add_base_energy`), а также гейт по флагу (`requires_flag`). Три полноценные ветки: «Путь Машин» (4 узла, производство/эффективность), «Путь Сознания» (5 узлов: `c_root`/`c_parallel`/`c_deep`/`c_insight`/`c_oversight` — вычисления и теха-раш, открыта с начала), «Путь Пустоты» (4 узла: `v_root`/`v_whisper`/`v_hunger`/`v_communion` — мощные, но рискованные эффекты; корень `v_root` имеет `requires_flag: "void_detected"`, остальные узлы Пустоты зависят от него и гейтятся транзитивно через `requires`).
- UI: правая колонка — кнопки «⌬ ДЕРЕВО ИССЛЕДОВАНИЙ» и «⟲ ВРЕМЕННАЯ ЛИНИЯ» (переход на полноэкранные графы) + список «Здания» (BuildingsPanel) инлайн, без вкладок. Топбар показывает Данные, Вычисления и Энергию (каждый со скоростью/статусом).
- Коррупция (GameState.corruption, 0..1): растёт от суммарной скорости производства (Corruption.update), даёт бонус к производству (get_production_bonus_mult, до +50% на 1.0) и усиливает плохие аномалии. Гасится кнопкой «Стабилизировать» (Corruption.purge, цена в Вычислениях растёт с коррупцией). При corruption ≥ 0.5 однократно ставится флаг GameState.flags["void_detected"] и пишется зловещий лог — точка крючка для веток Сознание/Пустота (L5).
- Аномалии (AnomaliesDB/Anomalies): глобальные временные эффекты, максимум одна активна одновременно. Таймер кулдауна взвешен коррупцией (выше коррупция → чаще и больше «глитчей», ниже → реже и больше «сигналов»). Эффекты: mult_production (множитель на время действия, применяется в Production.recompute глобально) и instant_data_seconds (разовый всплеск Данных). UI: CorruptionBar (бар целостности + кнопка стабилизации) под топбаром, AnomalyBanner (имя/эффект/обратный отсчёт) видим только во время активной аномалии.
- CRT-шейдер теперь пост-процесс (читает screen_texture): дрожание строк, хроматическая аберрация, скан-линии, выпадения строк и виньетка масштабируются параметром corruption, который main.gd обновляет каждый тик.
- Престиж «Перезагрузка временной линии» (Prestige): сворачивает текущий забег (resources/buildings/research/corruption/flags/run_best_data/run_peak_corruption сбрасываются), даёт Хроно-эхо по формуле sqrt(run_best_data / ECHO_SCALE) × (1 + 0.5 × run_peak_corruption) × echo_gain_mult (бонус за пиковую коррупцию). Мета-состояние (chrono_echo, meta_upgrades, prestige_count) переживает сброс и сохраняется.
- Мета-дерево (MetaDB/Prestige): 4 перка за Хроно-эхо — Эхо-курсор (автоклик данных), Остаточная память (×1.5 ко всему производству), Фрагмент прошлого (старт со 500 Данных после сброса, требует Остаточную память), Резонанс времени (×1.5 к будущему эхо, требует Фрагмент прошлого). Эффекты подключены в Production.recompute() (autoclick_rate, get_production_mult) и Prestige.echo_gain() (echo_gain_mult).
- Переиспользуемый компонент **TreeGraph** (`scripts/ui/screens/tree_graph.gd`, `class_name TreeGraph extends Control`): отрисовывает граф узлов-кружков по координатам `pos` (из словарей, которые отдаёт `node_provider: Callable`), рёбра — кубические Безье-кривые от предпосылок (`requires`) к узлу, цвет/прозрачность ребра зависят от состояния узла-потомка. Цвет/состояние узла: OWNED — заливка цветом + «✓»; AVAILABLE — тёмная заливка с цветной обводкой; LOCKED — серый, приглушённый. Перетаскивание ЛКМ по фону холста панорамирует граф; зума нет. Клик по узлу НЕ выполняет действие — открывает **окно деталей** (название, описание, эффект, стоимость, требования если заблокирован, состояние, кнопка действия с подписью `action_label`, активна только для AVAILABLE). Кнопка действия вызывает `action_handler: Callable(id) -> bool`; при успехе граф и окно обновляются (`refresh()`). Компонент ничего не знает про Research/Prestige/MetaDB — вся специфика приходит через адаптеры (`node_provider`/`action_handler`) и предрасчитанные строки (`cost_text`/`effect_text`/`req_text`/`action_label`).
- Дерево исследований (ResearchTreeScreen) переведено на TreeGraph: адаптер `_nodes()` собирает узлы ResearchDB (цвет ветки, состояние owned/available/locked, тексты эффекта/стоимости/требований, `action_label = "Изучить"`), `_do_action(id)` вызывает `Research.research(id)`. Шапка: «← НАЗАД», заголовок «ДЕРЕВО ИССЛЕДОВАНИЙ», счётчик Вычислений.
- Флаговый гейт контента: `Research.is_available(id)` проверяет `requires_flag` (если узел требует флаг, который не выставлен в `GameState.flags`, узел недоступен независимо от предпосылок) — единая точка истины для `research()` и адаптера UI. Для узла `v_root` (флаг `void_detected`, ставится в Corruption.update при corruption ≥ 0.5) окно деталей показывает подсказку «Требуется обнаружить повреждённый сектор (целостность < 50%)» вместо списка предпосылок. Это первый случай связки «повреждённый сектор → разблокировка контента»; шаблон пригоден для будущих сюжетных гейтов.
- Престиж как граф-экран (PrestigeScreen, `scripts/ui/screens/prestige_screen.gd`): тот же TreeGraph поверх MetaDB.get_list() (узлы окрашены в Palette.VOID), состояние OWNED/AVAILABLE/LOCKED по `Prestige.is_owned`/`Prestige.prereqs_met`, `cost_text = "N ЭХО"`, `effect_text` по типу эффекта (autoclick/mult_production/start_data/echo_gain_mult), `action_label = "Активировать"`, `_do_action(id)` вызывает `Prestige.buy(id)`. Шапка: «← НАЗАД», заголовок «ВРЕМЕННАЯ ЛИНИЯ», баланс ХРОНО-ЭХО, «Получишь: +M» (`Prestige.echo_gain()`), кнопка «Свернуть временную линию (+M эхо)» с двухшаговым подтверждением (3с таймаут, как в старой PrestigePanel) — вызывает `Prestige.do_prestige()`.
- Навигация экранов: главный экран (`_ops_screen`), «Дерево исследований» (`_tree_screen`, ResearchTreeScreen), «Временная линия» (`_prestige_screen`, PrestigeScreen) и «Крипто-ферма» (`_mining_screen`, MiningScreen) переключаются через `visible` в main.gd. Из правой колонки главного экрана — кнопки «⌬ ДЕРЕВО ИССЛЕДОВАНИЙ», «⟲ ВРЕМЕННАЯ ЛИНИЯ» и «⛏ КРИПТО-ФЕРМА»; «← НАЗАД» в шапке каждого экрана возвращает на главный экран. Вкладок (TabContainer) больше нет. CRT-оверлей и подача corruption — глобальные, поверх всех экранов.
- Крипто-экономика (L6, «игра в игре»): крипто-ресурсы хранятся в `GameState.resources` по списку `CryptoDB` (каркас на 6 видов, сидировано 2 — Хеш-осколок `hsh` и Энтропий `ent`). Риги-майнеры (`MiningDB.get_rigs()`) покупаются за Данные (геометрический рост цены через `Mining.rig_cost`) и медленно добывают свою крипту (`Mining.crypto_rate`, `Mining.update` тикает в game_loop.gd). Апгрейды разгона (`MiningDB.get_upgrades()`) покупаются ЗА КРИПТУ, имеют предпосылки и множат всю добычу (`Mining.mine_mult`). Ферма самодостаточна — не использует основную энергосеть, не тратит крипту на структуры (придёт в L7+).
- UI крипто-экономики: экран «КРИПТО-ФЕРМА» (MiningScreen) — списком (не граф): балансы крипты, риги (имя/×N/цена в Данных/кнопка «Собрать»), разгон (апгрейды владение/доступность/требования, кнопка «Активировать»). Левый сворачивающийся трекер (CryptoTracker) на главном экране: свёрнут по умолчанию (кнопка «КРИПТА ▸»), при разворачивании показывает баланс и /сек по каждой крипте; не уводит с главного экрана.
- Мульти-ресурсная цена построек (L7): `BuildingsDB` хранит цену как словарь `cost` (resource → base) + общий `cost_mult`; `Buildings.cost(id)` возвращает словарь resource→текущая цена (геометрический рост по count), `can_afford`/`buy` проверяют и списывают ВСЕ компоненты сразу.
- Разблокировка построек исследованиями (L7): постройка с полем `requires_research` недоступна для покупки, пока соответствующий узел не изучен (`Buildings.is_unlocked`). Демо — элитный `data_cluster` (50K Данных + 5K Вычислений + 10 Хеш-осколков, ×1.30 рост, производит 60 Данных/сек, потребляет 60 Энергии/сек), заперт за `m_power_grid` («Энергосеть v2»).
- Взаимоисключающие пути исследований (L7): поле `excludes` на узле — изучение одного навсегда закрывает другой (`Research.is_excluded`, симметрично проверяет оба направления, встроено в `is_available`). Демо-развилка в «Пути Машин»: `m_auto_scan` ↔ `m_data_compression` взаимно исключают друг друга.
- UI: BuildingsPanel показывает мульти-ресурсную цену («50.00K DATA · 5.00K ВЫЧ · 10 HSH», короткие имена через `ResourcesDB`/`CryptoDB`, спец-случай "compute" → "ВЫЧ"); запертые постройки показаны приглушённо с подсказкой «🔒 Требуется исследование: <имя>» и неактивной кнопкой; обновляется и на `Events.research_completed`. ResearchTreeScreen: для исключённого узла окно деталей показывает «Путь закрыт (выбран другой узел)» вместо списка предпосылок.

## Автозагрузки (порядок)
- GameState, Events, GameLoop, SaveManager

## Ресурсы (введены)
- data: Данные — базовая валюта, начисляется кликом по ядру и автоматизацией (Сканер), множится исследованиями.
- energy: Энергия — поток (не накапливается), производные поля в GameState (energy_production/energy_demand/power_ratio).
- compute: Вычисления — накапливаемый ресурс, производится Суперкомпьютером, тратится на исследования.
- hsh/ent (CryptoDB, каркас на 6, сидировано 2): Хеш-осколок и Энтропий — крипто-ресурсы, хранятся в `resources`, медленно добываются ригами (Mining), не тратятся (трата — L7+).

## Файлы и их роль
- scenes/main.tscn: единственная сцена — корневой Control + main.gd
- scripts/main.gd: собирает UI-дерево в коде — `_ops_screen` (топбар / CorruptionBar / AnomalyBanner / ядро + кнопки «Дерево исследований»/«Временная линия»/«Крипто-ферма» + BuildingsPanel / терминал / CryptoTracker слева), `_tree_screen` (ResearchTreeScreen), `_prestige_screen` (PrestigeScreen), `_mining_screen` (MiningScreen) — переключение через visible; CRT-оверлей (пост-процесс, кормит corruption каждый тик, поверх всех экранов), обработка клика по ядру, дебаг-сброс
- scripts/core/game_state.gd: autoload GameState — resources (data/compute/hsh/ent)/buildings/meta/research/corruption/flags + мета (chrono_echo/meta_upgrades/prestige_count) + трекинг забега (run_best_data/run_peak_corruption) + крипто-ферма (crypto_rigs/mining_upgrades) + транзиентные active_anomaly/anomaly_cooldown + производные поля энергосети и production_rates; `_init()` сидирует нулевые балансы для всех CryptoDB.ids()
- scripts/core/events.gd: autoload Events — шина сигналов (+ building_purchased, research_completed, anomaly_started, anomaly_ended, prestige_done, meta_upgrade_bought, crypto_rig_bought, mining_upgrade_bought)
- scripts/core/game_loop.gd: autoload GameLoop — тик (Anomalies → Production → Mining → Corruption → трекинг run_best_data/run_peak_corruption), автосейв
- scripts/core/save_manager.gd: autoload SaveManager — JSON-сейв (+ research, corruption, flags, chrono_echo, meta_upgrades, prestige_count, run_best_data, run_peak_corruption, crypto_rigs, mining_upgrades), оффлайн-прогресс по всем production_rates и crypto-rates (Mining.compute_crypto_rates), wipe
- scripts/data/resources_db.gd: ResourcesDB — определения "data", "energy", "compute"
- scripts/data/crypto_db.gd: CryptoDB — список крипто-ресурсов (каркас на 6, сидировано 2: hsh, ent), get_def/ids
- scripts/data/mining_db.gd: MiningDB — риги-майнеры (cost_base/cost_mult/cost_res/mines) и апгрейды разгона (requires/cost в крипте/mine_mult)
- scripts/data/buildings_db.gd: BuildingsDB — определения "scanner", "reactor", "supercomputer", "data_cluster" (элитная, мульти-ресурсная цена `cost` словарь + `cost_mult`, заперта за `requires_research`)
- scripts/data/research_db.gd: ResearchDB — ветки (id/name/color/locked) + список узлов с `pos`: Путь Машин (4 узла, `m_auto_scan`/`m_data_compression` взаимно исключают друг друга через `excludes`), Путь Сознания (5 узлов, открыта с начала), Путь Пустоты (4 узла, корень `v_root` с `requires_flag: "void_detected"`)
- scripts/data/anomalies_db.gd: AnomaliesDB — список определений аномалий (signal/glitch, эффекты, веса)
- scripts/data/meta_db.gd: MetaDB — список мета-перков (4 узла: autoclick, mult_production, start_data, echo_gain_mult), каждый с `pos` для графа
- scripts/systems/production.gd: Production — recompute() (энергосеть+троттлинг+мульти-ресурс+множители исследований+автоклик Prestige+глобальный множитель коррупции/аномалии/мета), update(), compute_rates()
- scripts/systems/buildings.gd: Buildings — get_def/count/cost (словарь resource→цена)/is_unlocked (по requires_research)/can_afford/buy (списывает все компоненты цены)
- scripts/systems/research.gd: Research — get_def/is_owned/prereqs_met/is_excluded (взаимоисключающие узлы через excludes)/is_available (учитывает requires_flag, excludes, игнорирует stub-узлы)/can_research/research + множители (mult_production, mult_building, add_base_energy)
- scripts/systems/corruption.gd: Corruption — update() (рост от интенсивности производства, флаг void_detected), get_production_bonus_mult, purge_cost/can_purge/purge
- scripts/systems/anomalies.gd: Anomalies — update() (таймер активной аномалии / кулдаун спавна), get_active_production_mult, взвешенный коррупцией выбор аномалии
- scripts/systems/prestige.gd: Prestige — echo_gain/can_prestige/do_prestige (сброс забега + head start), is_owned/prereqs_met/can_buy/buy перков, get_production_mult/get_echo_gain_mult/autoclick_rate
- scripts/systems/mining.gd: Mining — риги (rig_count/rig_cost/can_buy_rig/buy_rig), mine_mult (от апгрейдов разгона), crypto_rate/compute_crypto_rates/update (медленное накопление крипты каждый тик), апгрейды разгона (upg_owned/upg_can_buy/upg_buy, тратят крипту)
- scripts/ui/format.gd: Format — форматирование чисел
- scripts/ui/palette.gd: Palette — цветовые токены (+ ENERGY, COMPUTE, CORRUPT, SIGNAL, VOID)
- scripts/ui/theme_builder.gd: ThemeBuilder — Theme в коде
- scripts/ui/panels/topbar.gd: TopBar — Данные/Вычисления (значение+скорость) + Энергия (выработка/потребление, питание %, бар)
- scripts/ui/panels/terminal.gd: TerminalPanel — лог терминала
- scripts/ui/panels/buildings.gd: BuildingsPanel — список зданий, покупка, рефреш
- scripts/ui/panels/research.gd: ResearchPanel — старая списочная панель исследований, больше не подключена (заменена ResearchTreeScreen), оставлена неиспользуемой
- scripts/ui/panels/corruption_bar.gd: CorruptionBar — бар «ЦЕЛОСТНОСТЬ АРХИВА» + кнопка «Стабилизировать»
- scripts/ui/panels/anomaly_banner.gd: AnomalyBanner — баннер активной аномалии (имя/эффект/обратный отсчёт)
- scripts/ui/panels/prestige.gd: PrestigePanel — старая списочная панель «Временная линия», больше не подключена (заменена PrestigeScreen), оставлена неиспользуемой
- scripts/ui/screens/tree_graph.gd: TreeGraph — переиспользуемый компонент графа (узлы/рёбра/пан/окно деталей/действие через адаптеры node_provider и action_handler)
- scripts/ui/screens/research_tree.gd: ResearchTreeScreen — полноэкранный граф дерева исследований на TreeGraph (адаптеры _nodes/_do_action), шапка с кнопкой «← НАЗАД» и счётчиком Вычислений
- scripts/ui/screens/prestige_screen.gd: PrestigeScreen — полноэкранный граф мета-дерева на TreeGraph, шапка с балансом эхо, «получишь сейчас» и двухшаговым сворачиванием временной линии
- scripts/ui/screens/mining_screen.gd: MiningScreen — полноэкранный список-экран «КРИПТО-ФЕРМА»: балансы крипты (баланс+/сек), риги (имя/×N/описание/цена в Данных/кнопка «Собрать»), разгон (апгрейды владение/доступность/требования/кнопка «Активировать»); шапка «← НАЗАД»
- scripts/ui/panels/crypto_tracker.gd: CryptoTracker — сворачивающийся трекер у левого края главного экрана (по умолчанию свёрнут, кнопка «КРИПТА ▸/◂»), в развёрнутом виде показывает баланс и /сек по каждой крипте из CryptoDB
- shaders/crt.gdshader: CRT-постпроцесс (screen_texture: дрожание/аберрация/скан-линии/выпадения от corruption, виньетка, фликер)
- shaders/core.gdshader: анимированное «ядро»

## Точки расширения (где следующий слой подключается)
- BuildingsDB.get_list() — добавление новых зданий (контент, A2).
- ResearchDB.get_list() — все три ветки наполнены; новые эффекты, масштабирующиеся от коррупции (corruption-scaling), и более глубокие сюжетные гейты через `requires_flag` (поздние слои).
- Новые деревья/ветки (в т.ч. для будущих слоёв) подключаются как ещё один экран-граф через TreeGraph: достаточно реализовать `node_provider`/`action_handler`-адаптеры по контракту узла (id/title/desc/pos/color/state/cost_text/effect_text/req_text/action_label/requires) — сам TreeGraph и окно деталей переиспользуются без изменений.
- GameState.resources — следующие слои добавят новые накапливаемые ресурсы по аналогии с "data"/"compute".
- AnomaliesDB.get_list() — новые типы аномалий, в т.ч. интерактивные «поймай сигнал» (L6).
- MetaDB.get_list() — новые мета-перки, разблокировки веток/ресурсов и сквозное Осознание архива (L5/L8), сид-модификаторы таймлайнов (L9).
- CryptoDB.get_list() / MiningDB — ещё 4 крипто-вида и соответствующие риги/апгрейды разгона (контент); трата крипты на продвинутые структуры всех веток (частично уже реализована для data_cluster, дальше — контент).
- BuildingsDB.get_list() / requires_research — элитные структуры по веткам + энерго-ветка (→ L9); ResearchDB excludes — наполнение узлов с развилками и крипто-ценами (→ L10–12).

## Известные дыры/TODO
- Нет.
