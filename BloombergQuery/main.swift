import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    
    var window: NSWindow!
    var webView: WKWebView!
    
    // Méthode appelée lors du lancement de l'application
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Rediriger la sortie vers stdout (terminal principal)
        freopen("/dev/tty", "a", stdout)  // Cela redirige stdout vers le terminal actuel
        
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
        webView.navigationDelegate = self  // Associer AppDelegate comme délégué
        
        // Charger l'URL de Bloomberg
        if let url = URL(string: "https://www.bloomberg.com/markets2/api/history/ALGN%3AUS/PX_LAST?timeframe=1_MONTH&period=daily") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Code de nettoyage si nécessaire
    }
    
    // Méthode appelée lorsque la page est complètement chargée
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Page chargée avec succès")
        
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
            print("Données JSON extraites : \(jsonString)")
            
            // Optionnel : formater et afficher les données sous forme d'objet JSON lisible
            if let data = jsonString.data(using: .utf8) {
                do {
                    // Désérialiser les données JSON en un objet
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    
                    // Arrondir les valeurs numériques dans le JSON
                    if var jsonDict = jsonObject as? [String: Any], var priceArray = jsonDict["price"] as? [[String: Any]] {
                        for (index, item) in priceArray.enumerated() {
                            if var price = item["value"] as? Double {
                                // Arrondir la valeur à 2 décimales
                                priceArray[index]["value"] = round(price * 100) / 100
                            }
                        }
                        
                        jsonDict["price"] = priceArray
                        
                        // Convertir l'objet JSON modifié en une chaîne formatée
                        let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [.prettyPrinted])
                        
                        // Convertir les données formatées en chaîne
                        if let formattedJson = String(data: jsonData, encoding: .utf8) {
                            print("Objet JSON formaté : \(formattedJson)")
                        }
                    }
                } catch {
                    print("Erreur d'analyse JSON: \(error)")
                }
            }
        }
    }
}

// Utilisation de NSApplicationMain pour lancer l'application sans @main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

