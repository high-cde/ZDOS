package it.xzdos.mobile;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    private WebView webView;
    private String connectedWallet = null;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        webView = findViewById(R.id.webview);
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setLoadWithOverviewMode(true);
        webSettings.setUseWideViewPort(true);
        webSettings.setBuiltInZoomControls(false);
        webSettings.setDisplayZoomControls(false);

        webView.addJavascriptInterface(new WebAppInterface(), "AndroidWallet");
        webView.setWebViewClient(new WebViewClient());

        webView.loadUrl("https://high-cde.github.io/");

        handleIntent(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        handleIntent(intent);
    }

    private void handleIntent(Intent intent) {
        Uri data = intent.getData();
        if (data != null && "phantom".equals(data.getScheme())) {
            // Phantom deep link return (es. phantom://connect?public_key=...)
            String publicKey = data.getQueryParameter("public_key");
            if (publicKey != null) {
                connectedWallet = publicKey;
                injectWalletStatus(publicKey);
            }
        }
    }

    private void injectWalletStatus(String publicKey) {
        String js = "javascript:if(window.onWalletConnected){window.onWalletConnected('" + publicKey + "');}";
        webView.evaluateJavascript(js, null);
    }

    public class WebAppInterface {
        @JavascriptInterface
        public void connectPhantom() {
            // Deep link Phantom Connect
            String url = "https://phantom.app/ul/v1/connect?app_url=https://high-cde.github.io&redirect_link=phantom://connect";
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            startActivity(intent);
        }

        @JavascriptInterface
        public String getConnectedWallet() {
            return connectedWallet != null ? connectedWallet : "";
        }
    }

    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
