import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!
    var webView: WKWebView!
    
    // Méthode appelée lors du lancement de l'application
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Créer la fenêtre de l'application
        let windowSize = NSSize(width: 800, height: 600)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height),
                          styleMask: [.titled, .closable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Bloomberg Query"
        window.makeKeyAndOrderFront(nil)
        
        // Créer un WebView avec configuration
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences.javaScriptEnabled = true  // Activer JavaScript
        webView = WKWebView(frame: window.contentView!.frame, configuration: webConfiguration)
        window.contentView?.addSubview(webView)
        
        // Ajouter un délégué pour surveiller la fin du chargement
        webView.navigationDelegate = self
        
        // Charger l'URL de Bloomberg
        if let url = URL(string: "https://www.bloomberg.com/markets2/api/history/ALGN%3AUS/PX_LAST?timeframe=5_YEAR&period=daily") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Code de nettoyage si nécessaire
    }
}

extension AppDelegate: WKNavigationDelegate {
    
    // Méthode appelée lorsque la page est complètement chargée
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Page chargée avec succès")
        
        // Attendre un peu pour s'assurer que tout est bien chargé
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (html, error) in
            if let error = error {
                print("Erreur d'exécution JavaScript: \(error)")
                return
            }
            
            // Vérifier si nous avons bien chargé la page avec les données attendues
            guard let htmlString = html as? String else {
                print("Erreur : le contenu HTML est inexistant")
                return
            }
            
            // Vérifier si le JSON est dans le contenu de la page
            if htmlString.contains("Bloomberg") {
                print("Données JSON : \(htmlString)") // Afficher le contenu HTML pour voir si les données JSON sont présentes
            } else {
                print("Erreur d'analyse JSON: Le format attendu n'a pas été trouvé.")
            }
        }
    }
}

// Utilisation de NSApplicationMain pour lancer l'application sans @main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

