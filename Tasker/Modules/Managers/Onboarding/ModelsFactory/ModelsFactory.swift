//
//  ModelsFactory.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/7/25.
//

import Foundation
import Models
import SwiftUI

@Observable
final class ModelsFactory {
    private var dateManager: DateManagerProtocol
    
    private var calendar: Calendar {
        dateManager.calendar
    }
    private var now: Date {
        dateManager.currentTime
    }
    
    var today = DateComponents()
    
    init(dateManager: DateManagerProtocol) {
        self.dateManager = dateManager
        
        today.year = calendar.component(.year, from: now)
        today.month = calendar.component(.month, from: now)
        today.day = calendar.component(.day, from: now)
    }
    
    private var selectedDate: Double {
        calendar.startOfDay(for: now).timeIntervalSince1970
    }
    
    // MARK: - Localized String Helper
    
    struct LocalizedString {
        let defaultValue: String
        let localizations: [String: String]
        
        func localized(for locale: Locale = .current) -> String {
            let identifier = locale.identifier
            if let value = localizations[identifier] {
                return value
            }
            
            if let lang = locale.language.languageCode?.identifier, let value = localizations[lang] {
                return value
            }
            return defaultValue
        }
    }
    
    // MARK: - Task Texts
    
    private enum TaskText {
        static let bestAppTitle = LocalizedString(
            defaultValue: "📱 Install the Best App",
            localizations: [
                "ru": "📱 Установить лучшее приложение",
                "de": "📱 Installiere die beste App",
                "es": "📱 Instala la mejor aplicación",
                "es-419": "📱 Instala la mejor aplicación",
                "es-US": "📱 Instala la mejor aplicación",
                "fr": "📱 Installe la meilleure application",
                "fr-CA": "📱 Installe la meilleure application",
                "it": "📱 Installa la migliore app",
                "pt": "📱 Instale o melhor app",
                "pt-BR": "📱 Instale o melhor app",
                "pt-PT": "📱 Instale o melhor app"
            ]
        )
        
        static let bestAppDescription = LocalizedString(
            defaultValue: "Mega task. Install the one app to rule them all. So... you did it",
            localizations: [
                "ru": "Мега-задача. Установить лучшее приложение. Ну... мы справились.",
                "de": "Mega-Aufgabe. Installiere die eine App, die alle beherrscht. Also… du hast es geschafft",
                "es": "Mega tarea. Instala la aplicación que las domina todas. Así que... lo lograste.",
                "es-419": "Mega tarea. Instala la aplicación que las domina todas. Así que... lo lograste.",
                "es-US": "Mega tarea. Instala la aplicación que las domina todas. Así que... lo lograste.",
                "fr": "Méga tâche. Installe l’app qui les domine toutes. Alors… mission accomplie.",
                "fr-CA": "Méga tâche. Installe l’app qui les domine toutes. Alors… mission accomplie.",
                "it": "Mega compito. Installa l’app che domina tutte. Quindi... ce l’hai fatta",
                "pt": "Mega tarefa. Instale o app que governa todos. Então... você conseguiu.",
                "pt-BR": "Mega tarefa. Instale o app que governa todos. Então... você conseguiu.",
                "pt-PT": "Mega tarefa. Instale o app que governa todos. Então... você conseguiu."
            ]
        )
        
        static let planTomorrowTitle = LocalizedString(
            defaultValue: "🗓️ Plan Tomorrow",
            localizations: [
                "ru": "🗓️ План на завтра",
                "de": "🗓️ Plane morgen",
                "es": "🗓️ Planifica el mañana",
                "es-419": "🗓️ Planifica el mañana",
                "es-US": "🗓️ Planifica el mañana",
                "fr": "🗓️ Prépare demain",
                "fr-CA": "🗓️ Prépare demain",
                "it": "🗓️ Pianifica domani",
                "pt": "🗓️ Planeje o amanhã",
                "pt-BR": "🗓️ Planeje o amanhã",
                "pt-PT": "🗓️ Planeje o amanhã"
            ]
        )
        
        static let planTomorrowDescription = LocalizedString(
            defaultValue: "Maybe you'll save the world tomorrow. Might wanna write that down.",
            localizations: [
                "ru": "Может, завтра прийдется спасти мир. Лучше записать это.",
                "de": "Vielleicht rettest du morgen die Welt. Schreib’s lieber auf.",
                "es": "Quizá salves el mundo mañana. Mejor apúntalo.",
                "es-419": "Quizá salves el mundo mañana. Mejor apúntalo.",
                "es-US": "Quizá salves el mundo mañana. Mejor apúntalo.",
                "fr": "Peut-être que tu sauveras le monde demain. Tu devrais noter ça, au cas où.",
                "fr-CA": "Peut-être que tu sauveras le monde demain. Tu devrais noter ça, au cas où.",
                "it": "Magari domani salverai il mondo. Forse dovresti annotarlo.",
                "pt": "Talvez você salve o mundo amanhã. Melhor anotar isso.",
                "pt-BR": "Talvez você salve o mundo amanhã. Melhor anotar isso.",
                "pt-PT": "Talvez você salve o mundo amanhã. Melhor anotar isso."
            ]
        )
        
        static let randomHoursTitle = LocalizedString(
            defaultValue: "💡 Random Hour",
            localizations: [
                "ru": "💡 Случайный час",
                "de": "💡 Zufällige Stunde",
                "es": "💡 Una hora al azar",
                "es-419": "💡 Una hora al azar",
                "es-US": "💡 Una hora al azar",
                "fr": "💡 Une heure au hasard",
                "fr-CA": "💡 Une heure au hasard",
                "it": "💡 Un’ora a caso",
                "pt": "💡 Uma hora aleatória",
                "pt-BR": "💡 Uma hora aleatória",
                "pt-PT": "💡 Uma hora aleatória"
            ]
        )
        
        static let randomHoursDescription = LocalizedString(
            defaultValue: "Google something you don’t understand. Quantum foam? Why cats scream at 3 AM? Choose your adventure.",
            localizations: [
                "ru": "Погугли что-то непонятное. Квантовая пена? Почему коты орут по ночам? Выбери своё приключение.",
                "de": "Google etwas, das du nicht verstehst. Quanten-Schaum? Warum Katzen nachts schreien? Wähl dein Abenteuer.",
                "es": "Busca en Google algo que no entiendas. ¿Espuma cuántica? ¿Por qué los gatos gritan de noche? Elige tu aventura.",
                "es-419": "Busca en Google algo que no entiendas. ¿Espuma cuántica? ¿Por qué los gatos gritan de noche? Elige tu aventura.",
                "es-US": "Busca en Google algo que no entiendas. ¿Espuma cuántica? ¿Por qué los gatos gritan de noche? Elige tu aventura.",
                "fr": "Cherche sur Google quelque chose que tu ne comprends pas. Mousse quantique ? Pourquoi les chats crient la nuit ? Choisis ton aventure.",
                "fr-CA": "Cherche sur Google quelque chose que tu ne comprends pas. Mousse quantique ? Pourquoi les chats crient la nuit ? Choisis ton aventure.",
                "it": "Cerca su Google qualcosa che non capisci. Schiuma quantistica? Perché i gatti urlano di notte? Scegli la tua avventura.",
                "pt": "Pesquise no Google algo que você não entende. Espuma quântica? Por que os gatos gritam à noite? Escolha sua aventura.",
                "pt-BR": "Pesquise no Google algo que você não entende. Espuma quântica? Por que os gatos gritam à noite? Escolha sua aventura.",
                "pt-PT": "Pesquise no Google algo que você não entende. Espuma quântica? Por que os gatos gritam à noite? Escolha sua aventura."
            ]
        )
        
        static let readSomethingTitle = LocalizedString(
            defaultValue: "📚 Read Something That’s Not a Screen",
            localizations: [
                "ru": "📚 Почитать что-то не с экрана",
                "de": "📚 Lies etwas, das kein Bildschirm ist",
                "es": "📚 Lee algo que no sea una pantalla",
                "es-419": "📚 Lee algo que no sea una pantalla",
                "es-US": "📚 Lee algo que no sea una pantalla",
                "fr": "📚 Lis quelque chose qui n’est pas sur un écran",
                "fr-CA": "📚 Lis quelque chose qui n’est pas sur un écran",
                "it": "📚 Leggi qualcosa che non sia uno schermo",
                "pt": "📚 Leia algo que não seja uma tela",
                "pt-BR": "📚 Leia algo que não seja uma tela",
                "pt-PT": "📚 Leia algo que não seja uma tela"
            ]
        )
        
        static let readSomethingDescription = LocalizedString(
            defaultValue: "A book, a newspaper, a cereal box. Touch paper. Absorb knowledge.",
            localizations: [
                "ru": "Книга, газета, коробка хлопьев. Потрогай бумагу. Впитай знания.",
                "de": "Ein Buch, eine Zeitung, eine Cornflakes-Packung. Fühl das Papier. Sauge Wissen auf.",
                "es": "Un libro, un periódico, una caja de cereales. Toca el papel. Absorbe conocimiento.",
                "es-419": "Un libro, un periódico, una caja de cereales. Toca el papel. Absorbe conocimiento.",
                "es-US": "Un libro, un periódico, una caja de cereales. Toca el papel. Absorbe conocimiento.",
                "fr": "Un livre, un journal, une boîte de céréales. Touche le papier. Absorbe la sagesse.",
                "fr-CA": "Un livre, un journal, une boîte de céréales. Touche le papier. Absorbe la sagesse.",
                "it": "Un libro, un giornale, una scatola di cereali. Tocca la carta. Assorbi conoscenza.",
                "pt": "Um livro, um jornal, uma caixa de cereal. Toque o papel. Absorva conhecimento.",
                "pt-BR": "Um livro, um jornal, uma caixa de cereal. Toque o papel. Absorva conhecimento.",
                "pt-PT": "Um livro, um jornal, uma caixa de cereal. Toque o papel. Absorva conhecimento."
            ]
        )
    }
    
    // MARK: - Create Tasks
    
    func create(_ model: Models, repeatTask: RepeatTask? = .never) -> MainModel {
        switch model {
        case .bestApp:
            UITaskModel(
                .initial(
                    TaskModel(
                        title: TaskText.bestAppTitle.localized(),
                        description: TaskText.bestAppDescription.localized(),
                        createDate: Date.now.timeIntervalSince1970,
                        notificationDate: Date.now.timeIntervalSince1970,
                        done: [CompleteRecord(completedFor: selectedDate, timeMark: Date.now.timeIntervalSince1970)],
                        taskColor: .purple
                    )
                )
            )
            
        case .planForTommorow:
            UITaskModel(
                .initial(
                    TaskModel(
                        title: TaskText.planTomorrowTitle.localized(),
                        description: TaskText.planTomorrowDescription.localized(),
                        createDate: Date.now.timeIntervalSince1970,
                        notificationDate: Double(calendar.date(
                            bySettingHour: 20,
                            minute: 30,
                            second: 0,
                            of: repeatTask == .never ? .now : dateManager.sunday()
                        )!.timeIntervalSince1970),
                        repeatTask: repeatTask,
                        taskColor: .mint
                    )
                )
            )
            
        case .randomHours:
            UITaskModel(
                .initial(
                    TaskModel(
                        title: TaskText.randomHoursTitle.localized(),
                        description: TaskText.randomHoursDescription.localized(),
                        createDate: Date.now.timeIntervalSince1970,
                        notificationDate: Double(calendar.date(
                            bySetting: .hour,
                            value: 19,
                            of: calendar.date(from: today)!
                        )!.timeIntervalSince1970),
                        repeatTask: .never,
                        taskColor: .steelBlue
                    )
                )
            )
            
        case .readSomething:
            UITaskModel(
                .initial(
                    TaskModel(
                        title: TaskText.readSomethingTitle.localized(),
                        description: TaskText.readSomethingDescription.localized(),
                        createDate: Date.now.timeIntervalSince1970,
                        notificationDate: Double(calendar.date(
                            bySetting: .hour,
                            value: 19,
                            of: dateManager.thursday()
                        )!.timeIntervalSince1970),
                        repeatTask: .weekly,
                        taskColor: .brown
                    )
                )
            )
        }
    }
    
    // MARK: - Models Enum
    
    enum Models {
        case randomHours
        case bestApp
        case planForTommorow
        case readSomething
    }
}
