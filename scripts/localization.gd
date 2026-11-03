extends Node

# Localization singleton ("Loc" in project.godot).
#
# The prototype uses a small in-project dictionary instead of imported
# translation files so it can be dropped into an empty project with no editor
# import step. Every visible UI string is looked up here, and scene scripts
# listen to locale_changed to refresh themselves live.
#
# Adding a language:
#   1. Add its code to SUPPORTED_LOCALES and LANGUAGE_NAMES.
#   2. Add a dictionary with the same keys under TRANSLATIONS.
#   3. The Settings menu will pick up the new entry automatically.

signal locale_changed(new_locale: String)

const SUPPORTED_LOCALES: Array[String] = ["en", "ru"]

const LANGUAGE_NAMES := {
	"en": "English",
	"ru": "Русский",
}

const TRANSLATIONS := {
	"en": {
		"hud.objective": "ARCHIVE — FIRST DAY     ·     Review the three files on the desk.",
		"hud.progress": "REVIEWED  %d / %d",
		"hud.prompt": "[ E ]   READ FILE   ·   %s",
		"hud.controls": "WASD  MOVE     ·     MOUSE  LOOK     ·     E  READ     ·     ESC  SETTINGS",

		"doc.case_label": "ARCHIVE COPY  ·  DO NOT REMOVE",
		"doc.page_front": "SHEET 1 OF 2  ·  FRONT",
		"doc.page_back": "SHEET 2 OF 2  ·  REVERSE",
		"doc.blank_back": "The reverse side is blank.",
		"doc.read_both": "Read both sides before making a call.",
		"doc.already_flagged": "This file has already been flagged for review.",
		"doc.checking": "Cross-checking against the archive index...",
		"doc.correct": "Discrepancy flagged. The record will be pulled for review.",
		"doc.wrong": "No discrepancy. This record is clean; you have flagged an innocent file.",
		"doc.flip": "Flip",
		"doc.find_error": "Find Error",
		"doc.close": "Close",

		"dialogue.kicker": "RECORDS OFFICE  ·  BASEMENT  ·  AFTER HOURS",
		"dialogue.next": "Next",
		"dialogue.understood": "Understood",

		"final.kicker": "END OF SHIFT  ·  PRECINCT 7 ARCHIVE",
		"final.summary": "Shift over. Errors found: %d. Errors missed: %d.",
		"final.reprimand": "Reprimand received",
		"final.clean": "Shift closed without reprimand",
		"final.mistaken": "Mistaken flags: %d",
		"final.case_removed": "Case No. 1987-K has been removed from the record.",
		"final.next": "Next",

		"settings.title": "SETTINGS",
		"settings.subtitle": "AUDIO & LANGUAGE",
		"settings.kicker": "PAUSED  ·  ARCHIVE",
		"settings.audio": "AUDIO",
		"settings.sound": "Sound",
		"settings.sound_hint": "Rain, footsteps, paper and interface sounds.",
		"settings.volume": "Master volume",
		"settings.volume_value": "%d%%",
		"settings.language": "LANGUAGE",
		"settings.language_hint": "Interface text and documents change immediately.",
		"settings.close": "Close",
		"settings.esc_hint": "Esc — close and return to the archive",
		"settings.on": "On",
		"settings.off": "Off",

		# --- Chapter 2: The Duty Room ---------------------------------------
		"duty.hud.objective_ringing": "DUTY ROOM — NIGHT SHIFT     ·     The telephone is ringing.",
		"duty.hud.objective_between": "DUTY ROOM — NIGHT SHIFT     ·     The line is quiet. Wait for the next call.",
		"duty.hud.objective_done": "DUTY ROOM — NIGHT SHIFT     ·     Shift complete.",
		"duty.hud.progress": "CALL  %d / %d",
		"duty.hud.reprimands": "REPRIMANDS  %d / %d",
		"duty.hud.reputation": "REPUTATION  ·  %s",
		"duty.hud.controls": "WASD  MOVE     ·     MOUSE  LOOK     ·     E  ANSWER PHONE     ·     ESC  SETTINGS",
		"duty.hud.prompt_answer": "[ E ]   ANSWER PHONE",
		"duty.hud.prompt_phone": "[ E ]   DESK TELEPHONE",
		"duty.hud.incoming": "INCOMING CALL",
		"duty.hud.incoming_hint": "Approach the desk and press E to answer.",
		"duty.phone.label": "Desk Telephone",
		"duty.reputation.unknown": "UNKNOWN",
		"duty.reputation.honest": "HONEST",
		"duty.reputation.corrupt": "COMPROMISED",
		"duty.reputation.neutral": "UNKNOWN",
		"duty.settings.kicker": "PAUSED  ·  DUTY ROOM",
		"duty.settings.esc_hint": "Esc — close and return to the duty room",
		"station.settings.kicker": "PAUSED  ·  PRECINCT 7",
		"station.settings.esc_hint": "Esc — close and return to the station",
		"station.hud.kicker": "CURRENT OBJECTIVE",
		"station.hud.rank": "RANK  ·  %s",
		"station.hud.controls": "WASD  MOVE     ·     MOUSE  LOOK     ·     E  INTERACT     ·     ESC  SETTINGS",
		"station.prompt.talk": "[ E ]   TALK TO  %s",
		"station.prompt.take_folder": "[ E ]   TAKE THE FOLDERS",
		"station.prompt.chief_desk": "[ E ]   USE CHIEF'S DESK",
		"station.prompt.generic": "[ E ]   %s",
		"station.prompt.locker": "[ E ]   VLASOV'S LOCKER",
		"station.prompt.evidence": "[ E ]   SHOW THE KRAVTSOV REPORT",
		"station.dialogue.next": "Next",
		"station.dialogue.finish": "Finish",
		"station.dialogue.hint": "[ E / ENTER ]  CONTINUE",
		"station.dialogue.role_fallback": "PRECINCT 7",
		"station.role.chief": "CHIEF",
		"station.role.detective": "DETECTIVE",
		"station.role.clerk": "CLERK",
		"station.role.officer": "OFFICER",
		"station.role.secretary": "SECRETARY",
		"station.rank.clerk": "CLERK",
		"station.rank.duty_officer": "DUTY OFFICER",
		"station.objective.wait_chief": "Wait for Chief Arkady.",
		"station.objective.talk_chief": "Talk to Chief Arkady.",
		"station.objective.pick_folder": "Pick up the folders from the archive desk.",
		"station.objective.deliver_folder": "Deliver the folders to Chief Arkady's office on the second floor.",
		"station.objective.find_evidence": "Find the Kravtsov report in Vlasov's locker in the break room — or deliver the folders.",
		"station.objective.evidence_found": "The Kravtsov report is in your hands. Deliver the folders or put the report on the Chief's desk.",
		"station.objective.promotion_complete": "Promotion complete. You are now a Duty Officer.",
		"station.objective.promotion_with_evidence": "Promotion complete. The Kravtsov report is still in your pocket.",
		"station.objective.truth_kept": "You kept the report. The Chief will not forget this.",
		"station.toast.folder_taken": "FOLDERS TAKEN  ·  CHIEF'S OFFICE, SECOND FLOOR",
		"station.toast.new_objective": "NEW OBJECTIVE  ·  TAKE THE FOLDERS FROM THE ARCHIVE DESK",
		"station.toast.promoted": "PROMOTED  ·  DUTY OFFICER",
		"station.toast.promoted_with_evidence": "PROMOTED  ·  DUTY OFFICER  ·  THE REPORT IS STILL YOURS",
		"station.toast.chief_hurry": "Chief Arkady: \"My office. Don't keep me waiting.\"",
		"station.toast.wait_chief": "Wait for Chief Arkady before taking the folders.",
		"station.toast.detective_watching": "Detective Vlasov is watching the archive door.",
		"station.toast.detective_locker": "Vlasov: \"My locker. Break room. Decide who you want to be.\"",
		"station.toast.detective_choice": "Vlasov: \"Whatever you do next, I was never here.\"",
		"station.toast.tip_received": "VLASOV'S TIP  ·  A LOCKER IN THE BREAK ROOM",
		"station.toast.locker_locked": "The locker is locked. Talk to Vlasov first.",
		"station.toast.evidence_found": "KRAVTSOV REPORT IN HAND  ·  DECIDE WHAT TO DO",
		"station.toast.evidence_on_desk": "THE REPORT IS ON THE DESK  ·  MAKE YOUR CHOICE",
		"station.toast.truth_kept": "THE KRAVTSOV CASE  ·  YOU DID NOT BECOME PART OF IT",
		"station.toast.too_late": "You already handed over the folders. Too late for the report.",
		"station.toast.confronted_no_promotion": "After that conversation, there will be no promotion.",
		"station.toast.confrontation_over": "That conversation is over.",
		"station.toast.chief_coming": "Chief Arkady is still on his way. Give him a moment.",
		"station.toast.nothing_to_deliver": "The Chief's desk. You have nothing to deliver yet.",
		"station.toast.already_officer": "You are already a Duty Officer. The desk can wait.",
		"station.toast.no_dialogue": "%s doesn't have anything to say right now.",
		"duty.notice.reprimand": "REPRIMAND RECORDED  ·  %d / %d",
		"duty.notice.chief": "THE CHIEF WANTS TO SEE YOU",

		"phone.kicker": "INCOMING CALL  ·  PRECINCT 7  ·  NIGHT SHIFT",
		"phone.call_number": "CALL %d OF %d",
		"phone.incoming_title": "Incoming Call",
		"phone.incoming_meta": "LINE 2  ·  RECEIVER RINGING",
		"phone.incoming_body": "The telephone rattles on the desk. Somewhere beyond the static, someone is waiting.",
		"phone.answer": "Answer",
		"phone.meta": "CALLER  ·  %s",
		"phone.meta_in_call": "LINE 2  ·  RECEIVER OPEN",
		"phone.meta_feedback": "LINE 2  ·  CALL ENDED",
		"phone.twist_caller": "DISTORTED VOICE",
		"phone.twist_meta": "LINE 2  ·  SIGNAL DISTORTED  ·  CALLER UNKNOWN",
		"phone.action.dispatch": "Send Patrol",
		"phone.action.log": "Log in Journal",
		"phone.action.hangup": "Hang Up",
		"phone.action.agree": "Agree",
		"phone.action.refuse": "Refuse and Send Patrol",
		"phone.continue": "Continue",
		"phone.end_shift": "End Shift",
		"phone.feedback_title.good": "CALL CLOSED",
		"phone.feedback_title.neutral": "CALL CLOSED",
		"phone.feedback_title.reprimand": "REPRIMAND",
		"phone.feedback_title.duty_ended": "DUTY ENDED",
		"phone.feedback.note_reprimand": "REPRIMANDS  %d / %d",
		"phone.feedback.note_corruption": "CORRUPTION  +%d",
		"phone.feedback.note_honesty": "HONESTY  +%d",
		"phone.feedback.note_game_over": "THIRD REPRIMAND  ·  SHIFT TERMINATED",
		"phone.feedback.dispatch_correct": "Patrol 12 acknowledges. The engine turns over before you set the receiver down.",
		"phone.feedback.dispatch_wrong": "A patrol rolls for a call that never needed one. The dispatcher's silence says enough.",
		"phone.feedback.log_correct": "Entry accepted. The journal has one more line, and the night goes back to being quiet.",
		"phone.feedback.log_wrong_action": "You filed the call instead of acting on it. Paper will not stop a knife.",
		"phone.feedback.log_bad_entry": "The entry does not match the call. The desk sergeant will hear about this.",
		"phone.feedback.log_bad_entry_and_action": "The entry is wrong, and so was the decision to file it. Two marks against you.",
		"phone.feedback.hangup_wrong": "You set the receiver down. The ringing starts again somewhere behind your eyes.",
		"phone.feedback.twist_agree": "You write \"quiet\" beside 5 Lenin Street. The line goes dead. Somewhere upstairs, a chair scrapes back from a table.",
		"phone.feedback.twist_refuse": "You keep the receiver steady and send the patrol. The voice hisses, then cuts out. A minute later, a note slides under the door: the Chief wants to see you.",

		"logbook.kicker": "DUTY LOG  ·  PRECINCT 7  ·  NIGHT SHIFT",
		"logbook.page": "PAGE 1  ·  OPEN LOG",
		"logbook.title": "Log the Call",
		"logbook.subtitle": "Write exactly what you heard. The record is checked against the call.",
		"logbook.transcript_header": "CALL TRANSCRIPT",
		"logbook.name_label": "CALLER'S NAME",
		"logbook.name_placeholder": "Full name",
		"logbook.address_label": "ADDRESS",
		"logbook.address_placeholder": "Street and number",
		"logbook.hint": "Case, punctuation and extra spaces are ignored. Blank fields count as a reprimand.",
		"logbook.clear": "Clear",
		"logbook.submit": "Submit Entry",

		"results.kicker": "END OF SHIFT  ·  DUTY ROOM  ·  03:00",
		"results.title.game_over": "Dismissed.",
		"results.title.corrupt": "A quiet night. Too quiet.",
		"results.title.honest": "A report with your name on it.",
		"results.title.neutral": "Shift complete.",
		"results.summary.game_over": "Three reprimands in one night. The Chief does not ask questions. He just points at the door.",
		"results.summary.corrupt": "The Kravtsov call never happened. Your log says the street was quiet, and someone upstairs is grateful.",
		"results.summary.honest": "You refused the voice on the line and sent the patrol anyway. By morning, the Chief's office light is still on.",
		"results.summary.neutral": "The shift is over. The city keeps its secrets, and so do you.",
		"results.reprimands": "REPRIMANDS  %d / %d",
		"results.honesty": "HONESTY  +%d",
		"results.corruption": "CORRUPTION  +%d",
		"results.calls": "CALLS HANDLED  %d / %d",
		"results.reputation": "FINAL REPUTATION  ·  %s",
		"results.chief_notice": "A note is waiting on your desk: the Chief wants to see you at 08:00.",
		"results.restart": "Restart Shift",
	},
	"ru": {
		"hud.objective": "АРХИВ — ПЕРВЫЙ ДЕНЬ     ·     Изучите три дела на столе.",
		"hud.progress": "ИЗУЧЕНО  %d / %d",
		"hud.prompt": "[ E ]   ЧИТАТЬ ДЕЛО   ·   %s",
		"hud.controls": "WASD  ХОДЬБА     ·     МЫШЬ  ОБЗОР     ·     E  ЧИТАТЬ     ·     ESC  НАСТРОЙКИ",

		"doc.case_label": "АРХИВНАЯ КОПИЯ  ·  НЕ ВЫНОСИТЬ",
		"doc.page_front": "ЛИСТ 1 ИЗ 2  ·  ЛИЦЕВАЯ СТОРОНА",
		"doc.page_back": "ЛИСТ 2 ИЗ 2  ·  ОБОРОТ",
		"doc.blank_back": "Оборотная сторона пуста.",
		"doc.read_both": "Изучите обе стороны, прежде чем принять решение.",
		"doc.already_flagged": "Это дело уже отмечено для проверки.",
		"doc.checking": "Сверка с архивным указателем...",
		"doc.correct": "Расхождение отмечено. Дело будет передано на проверку.",
		"doc.wrong": "Расхождений нет. Дело в порядке — вы ошибочно отметили его.",
		"doc.flip": "Перевернуть",
		"doc.find_error": "Найти ошибку",
		"doc.close": "Закрыть",

		"dialogue.kicker": "АРХИВ  ·  ПОДВАЛ  ·  ПОСЛЕ СМЕНЫ",
		"dialogue.next": "Далее",
		"dialogue.understood": "Понял",

		"final.kicker": "КОНЕЦ СМЕНЫ  ·  АРХИВ 7-ГО УЧАСТКА",
		"final.summary": "Смена окончена. Найдено ошибок: %d. Пропущено ошибок: %d.",
		"final.reprimand": "Получен выговор",
		"final.clean": "Смена закрыта без выговора",
		"final.mistaken": "Ошибочных отметок: %d",
		"final.case_removed": "Дело № 1987-K изъято из архива.",
		"final.next": "Далее",

		"settings.title": "НАСТРОЙКИ",
		"settings.subtitle": "ЗВУК И ЯЗЫК",
		"settings.kicker": "ПАУЗА  ·  АРХИВ",
		"settings.audio": "ЗВУК",
		"settings.sound": "Звук",
		"settings.sound_hint": "Дождь, шаги, бумага и звуки интерфейса.",
		"settings.volume": "Общая громкость",
		"settings.volume_value": "%d%%",
		"settings.language": "ЯЗЫК",
		"settings.language_hint": "Текст интерфейса и документы меняются сразу.",
		"settings.close": "Закрыть",
		"settings.esc_hint": "Esc — закрыть и вернуться в архив",
		"settings.on": "Вкл",
		"settings.off": "Выкл",

		# --- Глава 2: Дежурная комната ---------------------------------------
		"duty.hud.objective_ringing": "ДЕЖУРНАЯ КОМНАТА — НОЧНАЯ СМЕНА     ·     Телефон звонит.",
		"duty.hud.objective_between": "ДЕЖУРНАЯ КОМНАТА — НОЧНАЯ СМЕНА     ·     Линия молчит. Ждите следующего звонка.",
		"duty.hud.objective_done": "ДЕЖУРНАЯ КОМНАТА — НОЧНАЯ СМЕНА     ·     Смена окончена.",
		"duty.hud.progress": "ЗВОНОК  %d / %d",
		"duty.hud.reprimands": "ВЫГОВОРЫ  %d / %d",
		"duty.hud.reputation": "РЕПУТАЦИЯ  ·  %s",
		"duty.hud.controls": "WASD  ХОДЬБА     ·     МЫШЬ  ОБЗОР     ·     E  ОТВЕТИТЬ     ·     ESC  НАСТРОЙКИ",
		"duty.hud.prompt_answer": "[ E ]   ОТВЕТИТЬ НА ЗВОНОК",
		"duty.hud.prompt_phone": "[ E ]   НАСТОЛЬНЫЙ ТЕЛЕФОН",
		"duty.hud.incoming": "ВХОДЯЩИЙ ЗВОНОК",
		"duty.hud.incoming_hint": "Подойдите к столу и нажмите E, чтобы ответить.",
		"duty.phone.label": "Настольный телефон",
		"duty.reputation.unknown": "НЕИЗВЕСТНО",
		"duty.reputation.honest": "ЧЕСТЕН",
		"duty.reputation.corrupt": "КОМПРОМЕТИРОВАН",
		"duty.reputation.neutral": "НЕИЗВЕСТНО",
		"duty.settings.kicker": "ПАУЗА  ·  ДЕЖУРНАЯ КОМНАТА",
		"duty.settings.esc_hint": "Esc — закрыть и вернуться в дежурную комнату",
		"station.settings.kicker": "ПАУЗА  ·  УЧАСТОК 7",
		"station.settings.esc_hint": "Esc — закрыть и вернуться на участок",
		"station.hud.kicker": "ТЕКУЩАЯ ЗАДАЧА",
		"station.hud.rank": "ЗВАНИЕ  ·  %s",
		"station.hud.controls": "WASD  ХОДЬБА     ·     МЫШЬ  ОБЗОР     ·     E  ВЗАИМОДЕЙСТВИЕ     ·     ESC  НАСТРОЙКИ",
		"station.prompt.talk": "[ E ]   ПОГОВОРИТЬ  ·  %s",
		"station.prompt.take_folder": "[ E ]   ВЗЯТЬ ПАПКИ",
		"station.prompt.chief_desk": "[ E ]   СТОЛ НАЧАЛЬНИКА",
		"station.prompt.generic": "[ E ]   %s",
		"station.prompt.locker": "[ E ]   ШКАФЧИК ВЛАСОВА",
		"station.prompt.evidence": "[ E ]   ПОКАЗАТЬ ОТЧЁТ КРАВЦОВА",
		"station.dialogue.next": "Далее",
		"station.dialogue.finish": "Закончить",
		"station.dialogue.hint": "[ E / ENTER ]  ПРОДОЛЖИТЬ",
		"station.dialogue.role_fallback": "УЧАСТОК 7",
		"station.role.chief": "НАЧАЛЬНИК",
		"station.role.detective": "ДЕТЕКТИВ",
		"station.role.clerk": "КЛЕРК",
		"station.role.officer": "ОФИЦЕР",
		"station.role.secretary": "СЕКРЕТАРЬ",
		"station.rank.clerk": "КЛЕРК",
		"station.rank.duty_officer": "ДЕЖУРНЫЙ ОФИЦЕР",
		"station.objective.wait_chief": "Дождитесь начальника Аркадия.",
		"station.objective.talk_chief": "Поговорите с начальником Аркадием.",
		"station.objective.pick_folder": "Возьмите папки с архивного стола.",
		"station.objective.deliver_folder": "Доставьте папки в кабинет начальника на втором этаже.",
		"station.objective.find_evidence": "Найдите отчёт Кравцова в шкафчике Власова в комнате отдыха — или отнесите папки начальнику.",
		"station.objective.evidence_found": "Отчёт Кравцова у вас. Отдайте папки или положите отчёт на стол начальника.",
		"station.objective.promotion_complete": "Повышение получено. Теперь вы дежурный офицер.",
		"station.objective.promotion_with_evidence": "Повышение получено. Отчёт Кравцова остался у вас.",
		"station.objective.truth_kept": "Вы сохранили отчёт. Начальник этого не забудет.",
		"station.toast.folder_taken": "ПАПКИ ВЗЯТЫ  ·  КАБИНЕТ НАЧАЛЬНИКА, ВТОРОЙ ЭТАЖ",
		"station.toast.new_objective": "НОВАЯ ЗАДАЧА  ·  ВОЗЬМИТЕ ПАПКИ С АРХИВНОГО СТОЛА",
		"station.toast.promoted": "ПОВЫШЕНИЕ  ·  ДЕЖУРНЫЙ ОФИЦЕР",
		"station.toast.promoted_with_evidence": "ПОВЫШЕНИЕ  ·  ДЕЖУРНЫЙ ОФИЦЕР  ·  ОТЧЁТ ОСТАЛСЯ У ВАС",
		"station.toast.chief_hurry": "Начальник Аркадий: «Мой кабинет. Не заставляйте себя ждать.»",
		"station.toast.wait_chief": "Дождитесь начальника Аркадия, прежде чем брать папки.",
		"station.toast.detective_watching": "Детектив Власов наблюдает за дверью архива.",
		"station.toast.detective_locker": "Власов: «Мой шкафчик. Комната отдыха. Решай, кем ты хочешь быть.»",
		"station.toast.detective_choice": "Власов: «Что бы ты ни сделал дальше, меня здесь не было.»",
		"station.toast.tip_received": "НАВОДКА ВЛАСОВА  ·  ШКАФЧИК В КОМНАТЕ ОТДЫХА",
		"station.toast.locker_locked": "Шкафчик заперт. Сначала поговорите с Власовым.",
		"station.toast.evidence_found": "ОТЧЁТ КРАВЦОВА У ВАС  ·  РЕШИТЕ, ЧТО ДЕЛАТЬ",
		"station.toast.evidence_on_desk": "ОТЧЁТ НА СТОЛЕ  ·  СДЕЛАЙТЕ ВЫБОР",
		"station.toast.truth_kept": "ДЕЛО КРАВЦОВА  ·  ВЫ НЕ СТАЛИ ЕГО ЧАСТЬЮ",
		"station.toast.too_late": "Вы уже сдали папки. Для отчёта слишком поздно.",
		"station.toast.confronted_no_promotion": "После этого разговора о звании можно забыть.",
		"station.toast.confrontation_over": "Этот разговор окончен.",
		"station.toast.chief_coming": "Начальник Аркадий ещё идёт. Подождите немного.",
		"station.toast.nothing_to_deliver": "Стол начальника. Вам пока нечего доставить.",
		"station.toast.already_officer": "Вы уже дежурный офицер. Стол подождёт.",
		"station.toast.no_dialogue": "%s сейчас не хочет говорить.",
		"duty.notice.reprimand": "ВЫГОВОР ЗАПИСАН  ·  %d / %d",
		"duty.notice.chief": "НАЧАЛЬНИК ХОЧЕТ ВАС ВИДЕТЬ",

		"phone.kicker": "ВХОДЯЩИЙ ЗВОНОК  ·  УЧАСТОК 7  ·  НОЧНАЯ СМЕНА",
		"phone.call_number": "ЗВОНОК %d ИЗ %d",
		"phone.incoming_title": "Входящий звонок",
		"phone.incoming_meta": "ЛИНИЯ 2  ·  ТРУБКА ЗВОНИТ",
		"phone.incoming_body": "Телефон дребезжит на столе. Где-то за шумом помех кто-то ждёт ответа.",
		"phone.answer": "Ответить",
		"phone.meta": "ЗВОНЯЩИЙ  ·  %s",
		"phone.meta_in_call": "ЛИНИЯ 2  ·  ТРУБКА СНЯТА",
		"phone.meta_feedback": "ЛИНИЯ 2  ·  ЗВОНОК ЗАВЕРШЁН",
		"phone.twist_caller": "ИСКАЖЁННЫЙ ГОЛОС",
		"phone.twist_meta": "ЛИНИЯ 2  ·  СИГНАЛ ИСКАЖЁН  ·  ЗВОНЯЩИЙ НЕИЗВЕСТЕН",
		"phone.action.dispatch": "Отправить наряд",
		"phone.action.log": "Записать в журнал",
		"phone.action.hangup": "Положить трубку",
		"phone.action.agree": "Согласиться",
		"phone.action.refuse": "Отказаться и отправить наряд",
		"phone.continue": "Продолжить",
		"phone.end_shift": "Закончить смену",
		"phone.feedback_title.good": "ЗВОНОК ЗАВЕРШЁН",
		"phone.feedback_title.neutral": "ЗВОНОК ЗАВЕРШЁН",
		"phone.feedback_title.reprimand": "ВЫГОВОР",
		"phone.feedback_title.duty_ended": "ДЕЖУРСТВО ОКОНЧЕНО",
		"phone.feedback.note_reprimand": "ВЫГОВОРЫ  %d / %d",
		"phone.feedback.note_corruption": "КОРРУПЦИЯ  +%d",
		"phone.feedback.note_honesty": "ЧЕСТНОСТЬ  +%d",
		"phone.feedback.note_game_over": "ТРЕТИЙ ВЫГОВОР  ·  СМЕНА ПРЕРВАНА",
		"phone.feedback.dispatch_correct": "Наряд 12 подтверждает. Мотор заводится раньше, чем вы кладёте трубку.",
		"phone.feedback.dispatch_wrong": "Наряд выезжает на вызов, который не требовал вмешательства. Молчание диспетчера красноречивее слов.",
		"phone.feedback.log_correct": "Запись принята. В журнале стало на одну строку больше, и ночь снова стала тихой.",
		"phone.feedback.log_wrong_action": "Вы подшили вызов вместо того, чтобы действовать. Бумага не остановит нож.",
		"phone.feedback.log_bad_entry": "Запись не совпадает с содержанием звонка. Дежурный сержант об этом узнает.",
		"phone.feedback.log_bad_entry_and_action": "Запись неверна, и решение подшить вызов тоже. Две отметки против вас.",
		"phone.feedback.hangup_wrong": "Вы кладёте трубку. Звон продолжается где-то в глубине сознания.",
		"phone.feedback.twist_agree": "Вы пишете «тихо» напротив улицы Ленина, 5. Линия обрывается. Наверху кто-то отодвигает стул от стола.",
		"phone.feedback.twist_refuse": "Вы не отпускаете трубку и отправляете наряд. Голос шипит и обрывается. Через минуту под дверь скользит записка: начальник хочет вас видеть.",

		"logbook.kicker": "ЖУРНАЛ ДЕЖУРСТВА  ·  УЧАСТОК 7  ·  НОЧНАЯ СМЕНА",
		"logbook.page": "СТРАНИЦА 1  ·  ОТКРЫТЫЙ ЖУРНАЛ",
		"logbook.title": "Записать звонок",
		"logbook.subtitle": "Запишите то, что услышали. Запись сверят с содержанием звонка.",
		"logbook.transcript_header": "ТЕКСТ ЗВОНКА",
		"logbook.name_label": "ИМЯ ЗВОНЯЩЕГО",
		"logbook.name_placeholder": "Полное имя",
		"logbook.address_label": "АДРЕС",
		"logbook.address_placeholder": "Улица и номер дома",
		"logbook.hint": "Регистр, пунктуация и лишние пробелы не учитываются. Пустые поля считаются выговором.",
		"logbook.clear": "Очистить",
		"logbook.submit": "Внести запись",

		"results.kicker": "КОНЕЦ СМЕНЫ  ·  ДЕЖУРНАЯ КОМНАТА  ·  03:00",
		"results.title.game_over": "Отстранены.",
		"results.title.corrupt": "Тихая ночь. Слишком тихая.",
		"results.title.honest": "Рапорт с вашим именем.",
		"results.title.neutral": "Смена окончена.",
		"results.summary.game_over": "Три выговора за одну ночь. Начальник не задаёт вопросов. Он просто указывает на дверь.",
		"results.summary.corrupt": "Звонка по делу Кравцова не было. В журнале записано, что улица была тихой, и наверху вам благодарны.",
		"results.summary.honest": "Вы отказались выполнять приказ голоса и всё равно отправили наряд. К утру в кабинете начальника всё ещё горит свет.",
		"results.summary.neutral": "Смена окончена. Город хранит свои секреты, а вы — свои.",
		"results.reprimands": "ВЫГОВОРЫ  %d / %d",
		"results.honesty": "ЧЕСТНОСТЬ  +%d",
		"results.corruption": "КОРРУПЦИЯ  +%d",
		"results.calls": "ОБРАБОТАНО ЗВОНКОВ  %d / %d",
		"results.reputation": "ИТОГОВАЯ РЕПУТАЦИЯ  ·  %s",
		"results.chief_notice": "На столе ждёт записка: начальник хочет видеть вас в 08:00.",
		"results.restart": "Начать смену заново",
	},
}

## Current two-letter locale code: "en" or "ru".
var locale: String = "ru"


func _ready() -> void:
	# Keep Godot's own locale in sync with our UI language. This also makes
	# future engine-provided strings behave consistently.
	TranslationServer.set_locale(locale)


## Changes the active language and notifies every listening UI.
func set_locale(locale_code: String) -> void:
	if not SUPPORTED_LOCALES.has(locale_code):
		return
	if locale_code == locale:
		return

	locale = locale_code
	TranslationServer.set_locale(locale_code)
	locale_changed.emit(locale_code)


## Returns a translated string. Optional args are applied with % formatting.
## Example: Loc.t("hud.progress", [2, 3])
func t(key: String, args: Array = []) -> String:
	var table: Dictionary = TRANSLATIONS.get(locale, TRANSLATIONS["en"])
	var fallback: Dictionary = TRANSLATIONS["en"]
	var text := str(table.get(key, fallback.get(key, key)))
	if args.is_empty():
		return text
	return text % args


## Picks a localized field from a data dictionary. Designers can store
## {"text": "...", "text_ru": "..."} in calls and other data resources; an empty
## Russian value falls back to English.
func pick(data: Dictionary, base_key: String) -> String:
	if locale == "ru":
		var localized := str(data.get(base_key + "_ru", ""))
		if not localized.strip_edges().is_empty():
			return localized
	return str(data.get(base_key, ""))


## Human-readable language name shown in the Settings menu.
func get_language_name(locale_code: String) -> String:
	return str(LANGUAGE_NAMES.get(locale_code, locale_code.to_upper()))


## Returns a copy so callers cannot mutate the supported-language list.
func get_supported_locales() -> Array[String]:
	return SUPPORTED_LOCALES.duplicate()


func is_russian() -> bool:
	return locale == "ru"
