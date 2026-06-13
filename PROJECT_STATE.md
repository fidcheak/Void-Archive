# PROJECT STATE — Архив Пустоты
Последний слой: L4
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
- Престиж «Перезагрузка временной линии» (Prestige): сворачивает текущий забег (resources/buildings/research/corruption/flags/run_best_data/run_peak_corruption сбрасываются), даёт Хроно-эхо по формуле sqrt(run_best_data / ECHO_SCALE) × (1 + 0.5 × run_peak_corruption) × echo_gain_mult (бонус за пиковую коррупцию). Мета-состояние (chrono_echo, meta_upgrades, prestige_count) переживает сброс и сохраняется.
- Мета-дерево (MetaDB/Prestige): 4 перка за Хроно-эхо — Эхо-курсор (автоклик данных), Остаточная память (×1.5 ко всему производству), Фрагмент прошлого (старт со 500 Данных после сброса, требует Остаточную память), Резонанс времени (×1.5 к будущему эхо, требует Фрагмент прошлого). Эффекты подключены в Production.recompute() (autoclick_rate, get_production_mult) и Prestige.echo_gain() (echo_gain_mult).
- UI: правая колонка — третья вкладка «Временная линия» (PrestigePanel): баланс эхо, счётчик свёрнутых линий, «получишь сейчас», кнопка сворачивания с двухшаговым подтверждением (3с таймаут), список мета-перков с предпосылками.

## Автозагрузки (порядок)
- GameState, Events, GameLoop, SaveManager

## Ресурсы (введены)
- data: Данные — базовая валюта, начисляется кликом по ядру и автоматизацией (Сканер), множится исследованиями.
- energy: Энергия — поток (не накапливается), производные поля в GameState (energy_production/energy_demand/power_ratio).
- compute: Вычисления — накапливаемый ресурс, производится Суперкомпьютером, тратится на исследования.

## Файлы и их роль
- scenes/main.tscn: единственная сцена — корневой Control + main.gd
- scripts/main.gd: собирает UI-дерево в коде (топбар / CorruptionBar / AnomalyBanner / ядро + TabContainer(Здания/Исследования/Временная линия) / терминал), CRT-оверлей (пост-процесс, кормит corruption каждый тик), обработка клика по ядру, дебаг-сброс
- scripts/core/game_state.gd: autoload GameState — resources (data/compute)/buildings/meta/research/corruption/flags + мета (chrono_echo/meta_upgrades/prestige_count) + трекинг забега (run_best_data/run_peak_corruption) + транзиентные active_anomaly/anomaly_cooldown + производные поля энергосети и production_rates
- scripts/core/events.gd: autoload Events — шина сигналов (+ building_purchased, research_completed, anomaly_started, anomaly_ended, prestige_done, meta_upgrade_bought)
- scripts/core/game_loop.gd: autoload GameLoop — тик (Anomalies → Production → Corruption → трекинг run_best_data/run_peak_corruption), автосейв
- scripts/core/save_manager.gd: autoload SaveManager — JSON-сейв (+ research, corruption, flags, chrono_echo, meta_upgrades, prestige_count, run_best_data, run_peak_corruption), оффлайн-прогресс по всем production_rates, wipe
- scripts/data/resources_db.gd: ResourcesDB — определения "data", "energy", "compute"
- scripts/data/buildings_db.gd: BuildingsDB — определения "scanner", "reactor", "supercomputer"
- scripts/data/research_db.gd: ResearchDB — ветки + список узлов (Путь Машин: 4 узла)
- scripts/data/anomalies_db.gd: AnomaliesDB — список определений аномалий (signal/glitch, эффекты, веса)
- scripts/data/meta_db.gd: MetaDB — список мета-перков (4 узла: autoclick, mult_production, start_data, echo_gain_mult)
- scripts/systems/production.gd: Production — recompute() (энергосеть+троттлинг+мульти-ресурс+множители исследований+автоклик Prestige+глобальный множитель коррупции/аномалии/мета), update(), compute_rates()
- scripts/systems/buildings.gd: Buildings — get_def/count/cost/can_afford/buy
- scripts/systems/research.gd: Research — get_def/is_owned/prereqs_met/is_available/can_research/research + множители (mult_production, mult_building, add_base_energy)
- scripts/systems/corruption.gd: Corruption — update() (рост от интенсивности производства, флаг void_detected), get_production_bonus_mult, purge_cost/can_purge/purge
- scripts/systems/anomalies.gd: Anomalies — update() (таймер активной аномалии / кулдаун спавна), get_active_production_mult, взвешенный коррупцией выбор аномалии
- scripts/systems/prestige.gd: Prestige — echo_gain/can_prestige/do_prestige (сброс забега + head start), is_owned/prereqs_met/can_buy/buy перков, get_production_mult/get_echo_gain_mult/autoclick_rate
- scripts/ui/format.gd: Format — форматирование чисел
- scripts/ui/palette.gd: Palette — цветовые токены (+ ENERGY, COMPUTE, CORRUPT, SIGNAL, VOID)
- scripts/ui/theme_builder.gd: ThemeBuilder — Theme в коде
- scripts/ui/panels/topbar.gd: TopBar — Данные/Вычисления (значение+скорость) + Энергия (выработка/потребление, питание %, бар)
- scripts/ui/panels/terminal.gd: TerminalPanel — лог терминала
- scripts/ui/panels/buildings.gd: BuildingsPanel — список зданий, покупка, рефреш
- scripts/ui/panels/research.gd: ResearchPanel — список исследований по веткам, изучение, рефреш
- scripts/ui/panels/corruption_bar.gd: CorruptionBar — бар «ЦЕЛОСТНОСТЬ АРХИВА» + кнопка «Стабилизировать»
- scripts/ui/panels/anomaly_banner.gd: AnomalyBanner — баннер активной аномалии (имя/эффект/обратный отсчёт)
- scripts/ui/panels/prestige.gd: PrestigePanel — баланс эхо, кнопка сворачивания (двухшаговое подтверждение), мета-дерево перков
- shaders/crt.gdshader: CRT-постпроцесс (screen_texture: дрожание/аберрация/скан-линии/выпадения от corruption, виньетка, фликер)
- shaders/core.gdshader: анимированное «ядро»

## Точки расширения (где следующий слой подключается)
- BuildingsDB.get_list() — добавление новых зданий (контент, A2).
- ResearchDB.get_list() / get_branches() — наполнение веток «Сознание» и «Пустота» по флагу GameState.flags["void_detected"], разблокировка запретных исследований (L5), новые типы эффектов.
- GameState.resources — следующие слои добавят новые накапливаемые ресурсы по аналогии с "data"/"compute".
- AnomaliesDB.get_list() — новые типы аномалий, в т.ч. интерактивные «поймай сигнал» (L6).
- MetaDB.get_list() — новые мета-перки, разблокировки веток/ресурсов и сквозное Осознание архива (L5/L8), сид-модификаторы таймлайнов (L9).

## Известные дыры/TODO
- Нет.
