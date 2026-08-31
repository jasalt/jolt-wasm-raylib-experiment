#include <emscripten/emscripten.h>
#include <raylib.h>

static unsigned int frame_count = 0;

EM_JS(void, set_ready, (unsigned int frame), {
  const status = document.getElementById("raylib-status");
  status.dataset.raylibState = "ready";
  status.textContent = `ready: frame ${frame}`;
});

static void update_draw_frame(void) {
  const int width = GetScreenWidth();
  const int height = GetScreenHeight();

  BeginDrawing();
  ClearBackground((Color){20, 24, 41, 255});
  DrawRectangle(36, 32, width - 72, height - 64, (Color){35, 45, 74, 255});
  DrawCircle(140, 150, 55, (Color){0, 228, 48, 255});
  DrawRectangle(240, 95, 180, 110, (Color){0, 121, 241, 255});
  DrawRectangle(510, 95, 120, 110, (Color){255, 203, 0, 255});
  DrawText("Raylib PLATFORM_WEB", 35, 245, 30, RAYWHITE);
  DrawText(TextFormat("frame: %u", frame_count), 35, 290, 22,
           (Color){200, 220, 255, 255});
  EndDrawing();

  frame_count++;
}

int main(void) {
  SetTraceLogLevel(LOG_ERROR);
  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  InitWindow(720, 360, "Raylib web diagnostic");
  SetTargetFPS(60);
  set_ready(frame_count);
  emscripten_set_main_loop(update_draw_frame, 0, 1);
  return 0;
}
