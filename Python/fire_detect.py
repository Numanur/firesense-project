import cv2
from ultralytics import YOLO
import time
import socketio
import base64

# =====================================================
# 1. SOCKET.IO CLIENT (USING NAMESPACE "/python")
# =====================================================

sio = socketio.Client()

# Change this to your Node server IP
NODE_SERVER_IP = "192.168.1.103"
NODE_SERVER_URL = f"http://{NODE_SERVER_IP}:3000"


@sio.event(namespace="/python")
def connect():
    print("🔥 Connected to Node.js Socket.IO server!")


@sio.event(namespace="/python")
def disconnect():
    print("❌ Disconnected from server!")


@sio.event(namespace="/python")
def connect_error(err):
    print("⚠️ Connection error:", err)


# Connect using namespace
try:
    sio.connect(NODE_SERVER_URL, namespaces=["/python"])
except Exception as e:
    print("❌ Socket.IO connection failed:", e)


# =====================================================
# 2. FIRE/SMOKE YOLO MODEL
# =====================================================

model = YOLO("best_2.pt")  # your model

# Your IP camera feed
cap = cv2.VideoCapture("http://192.168.1.107:8080/video")

prev_time = 0.0
delay = 0.5  # YOLO inference rate (a bit smoother now)
class_names = {0: "fire", 1: "smoke"}

ALERT_CONF_THRESH = 0.25
annotated_frame = None


# =====================================================
# 3. MAIN LOOP
# =====================================================

while True:
    ret, frame = cap.read()
    if not ret:
        print("❌ Failed to grab frame")
        break

    # 🔽 Step 1: resize frame to reduce load
    frame = cv2.resize(frame, (640, 360))

    if annotated_frame is None:
        annotated_frame = frame.copy()

    current_time = time.time()

    # Run YOLO every X seconds
    if current_time - prev_time >= delay:

        results = model(frame)

        # 🔽 Step 2: don't use results[0].plot(), just draw manually
        annotated_frame = frame.copy()

        fire_area_total = 0
        smoke_area_total = 0
        any_alert = False

        boxes = results[0].boxes
        if boxes is not None and len(boxes) > 0:
            cls_arr = boxes.cls.detach().cpu().numpy().astype(int)
            conf_arr = boxes.conf.detach().cpu().numpy()
            xyxy_arr = boxes.xyxy.detach().cpu().numpy().astype(int)

            for (cls_id, conf, (x1, y1, x2, y2)) in zip(cls_arr, conf_arr, xyxy_arr):
                area = (x2 - x1) * (y2 - y1)

                if cls_id == 0:
                    fire_area_total += area
                    color = (0, 0, 255)
                else:
                    smoke_area_total += area
                    color = (0, 165, 255)

                if conf >= ALERT_CONF_THRESH:
                    any_alert = True

                cv2.rectangle(annotated_frame, (x1, y1), (x2, y2), color, 2)
                cv2.putText(
                    annotated_frame,
                    f"{class_names.get(cls_id, 'obj')} {conf:.2f} : {int(area)} px^2",
                    (x1, max(0, y1 - 8)),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.6,
                    color,
                    2
                )

        print(f"🔥 Fire Area: {fire_area_total} px^2")
        print(f"💨 Smoke Area: {smoke_area_total} px^2")

        # =====================================================
        # 4. SEND FRAME & DATA TO NODE.JS (Socket.IO Emit)
        # =====================================================

        try:
            # 🔽 Step 3: stronger JPEG compression (smaller packets)
            ok, jpeg = cv2.imencode(".jpg", annotated_frame, [int(cv2.IMWRITE_JPEG_QUALITY), 40])
            if ok:
                b64_frame = base64.b64encode(jpeg.tobytes()).decode("utf-8")

                payload = {
                    "frame_b64": b64_frame,
                    "fire_area": int(fire_area_total),
                    "smoke_area": int(smoke_area_total),
                    "any_alert": bool(any_alert),
                    "timestamp": current_time
                }

                sio.emit("frame", payload, namespace="/python")

        except Exception as e:
            print("❌ Error transmitting frame:", e)

        prev_time = current_time

    # =====================================================
    # 5. LOCAL WINDOW PREVIEW (OPTIONAL)
    # =====================================================
    cv2.imshow("🔥 Fire & Smoke Detection - Live", annotated_frame)
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break


cap.release()
cv2.destroyAllWindows()
