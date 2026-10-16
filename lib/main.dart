
package com.darkgpt.chat;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.content.Context;
import android.widget.*;
import org.json.*;
import java.net.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends Activity {

    private final int BG = Color.rgb(8, 10, 16);
    private final int PANEL = Color.rgb(20, 24, 36);
    private final int BLUE = Color.rgb(57, 136, 255);

    // ضع رابط الخادم الحقيقي هنا
    private static final String API_URL =
        "https://YOUR-BACKEND-URL/chat";

    private LinearLayout messages;
    private EditText input;
    private ScrollView scroll;
    private Spinner modes;
    private Button send;
    private boolean loading = false;

    private final ExecutorService executor =
        Executors.newSingleThreadExecutor();

    private final String[] modeKeys = {
        "normal", "deep", "coding",
        "cybersecurity", "negative"
    };

    private final String[] modeNames = {
        "🤖 DarkGPT AI",
        "🧠 Deep Thinking",
        "💻 Coding AI",
        "🛡️ Cybersecurity",
        "⚫ Dark Analysis"
    };

    private final JSONArray history = new JSONArray();

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);

        getWindow().setStatusBarColor(BG);
        getWindow().setNavigationBarColor(BG);

        buildUI();
        addBubble("مرحباً بك في DarkGPT AI! كيف أساعدك؟",
            false, false);
    }

    private GradientDrawable background(int color, int radius) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(color);
        d.setCornerRadius(radius);
        return d;
    }

    private TextView label(String value, int size) {
        TextView t = new TextView(this);
        t.setText(value);
        t.setTextSize(size);
        t.setTextColor(Color.WHITE);
        return t;
    }

    private void buildUI() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(12, 8, 12, 8);
        root.setBackgroundColor(BG);
        setContentView(root);

        LinearLayout header = new LinearLayout(this);
        header.setGravity(Gravity.CENTER_VERTICAL);

        TextView title = label("DarkGPT AI", 23);
        title.setTypeface(null, Typeface.BOLD);
        header.addView(title, new LinearLayout.LayoutParams(
            0, 60, 1
        ));

        Button fresh = new Button(this);
        fresh.setText("＋");
        header.addView(fresh);
        root.addView(header);

        fresh.setOnClickListener(v -> {
            if (loading) return;
            messages.removeAllViews();
            while (history.length() > 0) history.remove(0);
            addBubble("بدأت محادثة جديدة.", false, false);
        });

        modes = new Spinner(this);
        ArrayAdapter<String> adapter = new ArrayAdapter<>(
            this,
            android.R.layout.simple_spinner_item,
            modeNames
        );
        adapter.setDropDownViewResource(
            android.R.layout.simple_spinner_dropdown_item
        );
        modes.setAdapter(adapter);
        root.addView(modes);

        scroll = new ScrollView(this);
        messages = new LinearLayout(this);
        messages.setOrientation(LinearLayout.VERTICAL);
        messages.setPadding(2, 16, 2, 16);
        scroll.addView(messages);

        root.addView(scroll, new LinearLayout.LayoutParams(
            -1, 0, 1
        ));

        LinearLayout composer = new LinearLayout(this);
        composer.setGravity(Gravity.CENTER_VERTICAL);

        input = new EditText(this);
        input.setTextColor(Color.WHITE);
        input.setHintTextColor(Color.LTGRAY);
        input.setHint("اكتب رسالتك...");
        input.setTextSize(15);
        input.setPadding(16, 8, 16, 8);
        input.setMinHeight(52);
        input.setMaxLines(5);
        input.setBackground(background(PANEL, 24));

        composer.addView(input, new LinearLayout.LayoutParams(
            0, -2, 1
        ));

        send = new Button(this);
        send.setText("↑");
        send.setTextColor(Color.WHITE);
        send.setBackground(background(BLUE, 24));

        LinearLayout.LayoutParams bp =
            new LinearLayout.LayoutParams(60, 52);
        bp.setMargins(6, 0, 0, 0);
        composer.addView(send, bp);

        root.addView(composer);
        send.setOnClickListener(v -> sendMessage());
    }

    private void addBubble(String text, boolean user, boolean error) {
        TextView bubble = label(text, 15);
        bubble.setPadding(14, 12, 14, 12);
        bubble.setTextIsSelectable(true);
        bubble.setBackground(background(
            error ? Color.rgb(65, 27, 36) :
            user ? Color.rgb(23, 59, 114) : PANEL,
            20
        ));

        LinearLayout row = new LinearLayout(this);
        row.setGravity(user ? Gravity.RIGHT : Gravity.LEFT);
        row.addView(bubble);

        LinearLayout.LayoutParams p =
            new LinearLayout.LayoutParams(-1, -2);
        p.setMargins(0, 0, 0, 12);
        messages.addView(row, p);

        scroll.post(() -> scroll.fullScroll(View.FOCUS_DOWN));
    }

    private void sendMessage() {
        if (loading) return;

        final String question = input.getText().toString().trim();
        if (question.isEmpty()) return;

        if (API_URL.contains("YOUR-BACKEND-URL")) {
            addBubble(
                "أضف رابط الخادم الحقيقي في API_URL أولاً.",
                false, true
            );
            return;
        }

        final String mode =
            modeKeys[modes.getSelectedItemPosition()];

        JSONArray oldHistory = new JSONArray();
        for (int i = 0; i < history.length(); i++) {
            oldHistory.put(history.optJSONObject(i));
        }

        input.setText("");
        ((InputMethodManager) getSystemService(
            Context.INPUT_METHOD_SERVICE
        )).hideSoftInputFromWindow(input.getWindowToken(), 0);

        addBubble(question, true, false);
        loading = true;
        send.setEnabled(false);

        final TextView waiting = label("DarkGPT يفكر...", 14);
        messages.addView(waiting);
        scroll.post(() -> scroll.fullScroll(View.FOCUS_DOWN));

        executor.execute(() -> {
            String answer;
            boolean failed = false;

            try {
                JSONObject payload = new JSONObject();
                payload.put("message", question);
                payload.put("mode", mode);
                payload.put("history", oldHistory);

                HttpURLConnection conn =
                    (HttpURLConnection) new URL(API_URL)
                        .openConnection();

                conn.setRequestMethod("POST");
                conn.setConnectTimeout(15000);
                conn.setReadTimeout(90000);
                conn.setDoOutput(true);
                conn.setRequestProperty(
                    "Content-Type", "application/json; charset=UTF-8"
                );

                try (OutputStream out = conn.getOutputStream()) {
                    out.write(payload.toString().getBytes(
                        StandardCharsets.UTF_8
                    ));
                }

                int status = conn.getResponseCode();
                InputStream stream = status >= 200 && status < 300
                    ? conn.getInputStream()
                    : conn.getErrorStream();

                StringBuilder response = new StringBuilder();

                if (stream != null) {
                    try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(
                            stream, StandardCharsets.UTF_8
                        ))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            response.append(line);
                        }
                    }
                }
                conn.disconnect();

                if (status < 200 || status >= 300) {
                    throw new IOException("HTTP " + status);
                }

                JSONObject data = new JSONObject(response.toString());
                answer = data.optString("reply",
                    data.optString("message",
                    data.optString("response",
                        "لم يرجع الخادم إجابة.")));

                JSONObject u = new JSONObject();
                u.put("role", "user");
                u.put("content", question);
                history.put(u);

                JSONObject a = new JSONObject();
                a.put("role", "assistant");
                a.put("content", answer);
                history.put(a);

            } catch (Exception e) {
                answer = "فشل الاتصال بالخادم. تحقق من الرابط "
                    + "والإنترنت وإعدادات الخادم.";
                failed = true;
            }

            final String result = answer;
            final boolean isError = failed;

            runOnUiThread(() -> {
                messages.removeView(waiting);
                addBubble(result, false, isError);
                loading = false;
                send.setEnabled(true);
            });
        });
    }

    @Override
    protected void onDestroy() {
        executor.shutdownNow();
        super.onDestroy();
    }
}
