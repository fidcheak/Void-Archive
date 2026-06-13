# PROJECT STATE — Архив Пустоты
Последний слой: L3
Движок: Godot 4.x. Запуск: F5.

## Что уже работает
- Каркас проекта, автозагрузки, дизайн-система (Palette/Theme/CRT).
- Терминальный экран с пульсирующим вращающимся «ядром» по центру.
- Клик по ядру → +1 Данные, счётчик обновляется, терминал пишет строки.
- Игровой цикл (_process, dt-кламп), автосейв каждые ~15с, оффлайн-расчёт по всем накапливаемым ресурсам (production_rates).
- Энергосеть как поток: energy_production/energy_demand/power_ratio пересчитываются каждый тик в Production.recompute(), троттлят производство потребителей энергии. Базовая мощность = BASE_ENERGY + бонусы исследований (add_base_energy).
- Здания: Сканер данных (Данные, ест Энергию), Реактор (Энергия), Суперкомпьютер (Вычисления, ест Энергию). Покупка через Buildings.buy(), цена растёт геометрически.
- Производство обобщено: GameState.production_rates — словарь resource→rate для всех накапливаемых ресурсов (data, compute), учитывает множители исследований (mult_production, mult_building).
- Система исследований (Research): предпосылки, стоимость в Вычислениях, эффекты-множители. Заполнена ветка «Путь Машин» (4 узла); «Сознание»/«Пустота» — заглушки [ДАННЫЕ ПОВРЕЖДЕНЫ].
- UI: правая колонка — TabContainer с вкладками «Здания» (BuildingsPanel) и «Исследования» (ResearchPanel). Топбар показывает Данные, Вычисления и Энергию (каждый со скоростью/статусом).
- Коррупция (GameState.corruption, 0..1): растёт от суммарной скорости производства (Corruption.update), даёт бонус к производству (get_production_bonus_mult, до +50% на 1.0) и усиливает плохие аномалии. Гасится кнопкой «Стабилизировать» (Corruption.purge, цена в Вычислениях растёт с коррупцией). При corruption ≥ 0.5 однократно ставится флаг GameState.flags["void_detected"] и пишется зловещий лог — точка крючка для веток Сознание/Пустота (L5).
- Аномалии (AnomaliesDB/Anomalies): глобальные временные эффекты, максимум одна активна одновременно. Таймер кулдауна взвешен коррупцией (выше коррупция → чаще и больше «глитчей», ниже → реже и больше «сигналов»). Эффекты: mult_production (множитель на время действия, применяется в Production.recompute глобально) и instant_data_seconds (разовый всплеск Данных). UI: CorruptionBar (бар целостности + кнопка стабилизации) под топбаром, AnomalyBanner (имя/эффект/обратный отсчёт) видим только во время активной аномалии.
- CRT-шейдер теперь пост-процесс (читает screen_texture): дрожание строк, хроматическая аберрация, скан-линии, выпадения строк и виньетка масштабируются параметром corruption, который main.gd обновляет каждый тик.

## Автозагрузки (порядок)
- GameState, Events, GameLoop, SaveManager

## Ресурсы (введены)
- data: Данные — базовая валюта, начисляется кликом по ядру и автоматизацией (Сканер), множится исследованиями.
- energy: Энергия — поток (не накапливается), производные поля в GameState (energy_production/energy_demand/power_ratio).
- compute: Вычисления — накапливаемый ресурс, производится Суперкомпьютером, тратится на исследования.

## Файлы и их роль
- scenes/main.tscn: единственная сцена — корневой Control + main.gd
- scripts/main.gd: собирает UI-дерево в коде (топбар / CorruptionBar / AnomalyBanner / ядро + TabContainer(Здания/Исследования) / терминал), CRT-оверлей (пост-процесс, кормит corruption каждый тик), обработка клика по ядру, дебаг-сброс
- scripts/core/game_state.gd: autoload GameState — resources (data/compute)/buildings/meta/research/corruption/flags + транзиентные active_anomaly/anomaly_cooldown + производные поля энергосети и production_rates
- scripts/core/events.gd: autoload Events — шина сигналов (+ building_purchased, research_completed, anomaly_started, anomaly_ended)
- scripts/core/game_loop.gd: autoload GameLoop — тик (Anomalies → Production → Corruption), автосейв
- scripts/core/save_manager.gd: autoload SaveManager — JSON-сейв (+ research, corruption, flags), оффлайн-прогресс по всем production_rates, wipe
- scripts/data/resources_db.gd: ResourcesDB — определения "data", "energy", "compute"
- scripts/data/buildings_db.gd: BuildingsDB — определения "scanner", "reactor", "supercomputer"
- scripts/data/research_db.gd: ResearchDB — ветки + список узлов (Путь Машин: 4 узла)
- scripts/data/anomalies_db.gd: AnomaliesDB — список определений аномалий (signal/glitch, эффекты, веса)
- scripts/systems/production.gd: Production — recompute() (энергосеть+троттлинг+мульти-ресурс+множители исследований+глобальный множитель коррупции/аномалии), update(), compute_rates()
- scripts/systems/buildings.gd: Buildings — get_def/count/cost/can_afford/buy
- scripts/systems/research.gd: Research — get_def/is_owned/prereqs_met/is_available/can_research/research + множители (mult_production, mult_building, add_base_energy)
- scripts/systems/corruption.gd: Corruption — update() (рост от интенсивности производства, флаг void_detected), get_production_bonus_mult, purge_cost/can_purge/purge
- scripts/systems/anomalies.gd: Anomalies — update() (таймер активной аномалии / кулдаун спавна), get_active_production_mult, взвешенный коррупцией выбор аномалии
- scripts/ui/format.gd: Format — форматирование чисел
- scripts/ui/palette.gd: Palette — цветовые токены (+ ENERGY, COMPUTE, CORRUPT, SIGNAL)
- scripts/ui/theme_builder.gd: ThemeBuilder — Theme в коде
- scripts/ui/panels/topbar.gd: TopBar — Данные/Вычисления (значение+скорость) + Энергия (выработка/потребление, питание %, бар)
- scripts/ui/panels/terminal.gd: TerminalPanel — лог терминала
- scripts/ui/panels/buildings.gd: BuildingsPanel — список зданий, покупка, рефреш
- scripts/ui/panels/research.gd: ResearchPanel — список исследований по веткам, изучение, рефреш
- scripts/ui/panels/corruption_bar.gd: CorruptionBar — бар «ЦЕЛОСТНОСТЬ АРХИВА» + кнопка «Стабилизировать»
- scripts/ui/panels/anomaly_banner.gd: AnomalyBanner — баннер активной аномалии (имя/эффект/обратный отсчёт)
- shaders/crt.gdshader: CRT-постпроцесс (screen_texture: дрожание/аберрация/скан-линии/выпадения от corruption, виньетка, фликер)
- shaders/core.gdshader: анимированное «ядро»

## Точки расширения (где следующий слой подключается)
- BuildingsDB.get_list() — добавление новых зданий (контент, A2).
- ResearchDB.get_list() / get_branches() — наполнение веток «Сознание» и «Пустота» по флагу GameState.flags["void_detected"], разблокировка запретных исследований (L5), новые типы эффектов.
- GameState.resources — следующие слои добавят новые накапливаемые ресурсы по аналогии с "data"/"compute".
- AnomaliesDB.get_list() — новые типы аномалий, в т.ч. интерактивные «поймай сигнал» (L6).

## Известные дыры/TODO
- Нет.
