import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    
    var window: NSWindow!
    var webView: WKWebView!
    var ticker: String!
    
    // Méthode appelée lors du lancement de l'application
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Récupérer le ticker à partir des arguments en ligne de commande
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.count > 1 {
            ticker = arguments[1]
        } else {
            print("Erreur : Aucun ticker fourni en paramètre.")
            return
        }
        
        // Rediriger la sortie vers stdout (terminal principal)
        freopen("/dev/tty", "a", stdout)  // Cela redirige stdout vers le terminal actuel
        
        // Créer la fenêtre de l'application
        let windowSize = NSSize(width: 800, height: 600)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height),
                          styleMask: [.titled, .closable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Bloomberg Query Webview"
        
        // Créer un WebView avec configuration
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences.javaScriptEnabled = true  // Activer JavaScript
        webView = WKWebView(frame: window.contentView!.frame, configuration: webConfiguration)
        window.contentView?.addSubview(webView)
        
        // Ajouter un délégué pour surveiller la fin du chargement
        webView.navigationDelegate = self  // Associer AppDelegate comme délégué
        
        // Encoder le ticker pour l'URL
        if let encodedTicker = ticker.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            // Construire l'URL avec le ticker encodé
            let urlString = "https://www.bloomberg.com/markets2/api/history/\(encodedTicker)/PX_LAST?timeframe=1_MONTH&period=daily"
            
            if let url = URL(string: urlString) {
                let request = URLRequest(url: url)
                webView.load(request)
            } else {
                print("Erreur : URL malformée.")
            }
        } else {
            print("Erreur : Échec de l'encodage du ticker.")
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Code de nettoyage si nécessaire
    }
    
    // Méthode appelée lorsque la page est complètement chargée
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Attendre un peu pour s'assurer que tout est bien chargé
        webView.evaluateJavaScript("document.querySelector('pre').textContent") { (result, error) in
            if let error = error {
                print("Erreur d'exécution JavaScript lors de l'extraction des données JSON: \(error)")
                return
            }
            
            guard let jsonString = result as? String else {
                print("Aucune donnée JSON trouvée.")
                return
            }
            
            // Si les données JSON sont récupérées, essayer de les analyser
            //print(jsonString)
            
            // Option 1 : Écrire les données dans un fichier JSON
            self.writeJSONToFile(jsonString)
        }
    }
    
    // Fonction pour écrire les données JSON dans un fichier avec le nom du ticker
    func writeJSONToFile(_ jsonString: String) {
        // Créer le chemin du fichier avec l'extension .json
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        let tickerUnwrapped=ticker?.components(separatedBy: ":").first ?? "unknown"
        let filePath = "\(currentDirectory)/\(tickerUnwrapped).json"
        
        // Convertir la chaîne JSON en données
        if let jsonData = jsonString.data(using: .utf8) {
            // Écrire les données dans le fichier
            do {
                try jsonData.write(to: URL(fileURLWithPath: filePath))
                print("Données JSON écrites dans le fichier : \(filePath)")
            } catch {
                print("Erreur lors de l'écriture du fichier JSON : \(error)")
            }
        } else {
            print("Erreur de conversion de la chaîne JSON en données")
        }
        NSApp.terminate(nil)
    }
    
}

// Utilisation de NSApplicationMain pour lancer l'application sans @main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

