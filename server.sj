const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// ------------------ تخزين البيانات في الذاكرة ------------------
let players = {};          // { username: { placeId, jobId, lastSeen } }
let commands = {};         // { commanderName: { message, time } }

// ------------------ تنظيف اللاعبين غير النشطين كل دقيقة ------------------
setInterval(() => {
    const now = Date.now();
    for (let name in players) {
        if (now - players[name].lastSeen > 30000) { // 30 ثانية
            delete players[name];
        }
    }
}, 60000);

// ------------------ نقطة النهاية لتسجيل وجود اللاعب ------------------
app.post('/ping', (req, res) => {
    const { username, placeId, jobId } = req.body;
    if (!username) return res.status(400).json({ error: 'username required' });
    
    players[username] = {
        placeId: placeId || 0,
        jobId: jobId || '',
        lastSeen: Date.now()
    };
    res.json({ status: 'ok' });
});

// ------------------ قائمة جميع اللاعبين النشطين ------------------
app.get('/players', (req, res) => {
    const active = Object.keys(players);
    res.json(active);
});

// ------------------ تحديث أمر جديد من قائد ------------------
app.post('/update', (req, res) => {
    const { username, message, time } = req.body;
    if (!username || !message) {
        return res.status(400).json({ error: 'username and message required' });
    }
    commands[username] = {
        message: message,
        time: time || Date.now()
    };
    res.json({ status: 'ok' });
});

// ------------------ جلب آخر أمر لقائد معين ------------------
app.get('/data/:commander', (req, res) => {
    const commander = req.params.commander;
    const cmd = commands[commander];
    if (cmd) {
        res.json({
            username: commander,
            message: cmd.message,
            time: cmd.time
        });
    } else {
        res.json({ username: commander, message: '', time: 0 });
    }
});

// ------------------ الحصول على معلومات لاعب للانضمام إليه ------------------
app.get('/target_info', (req, res) => {
    const target = req.query.username;
    if (!target) return res.status(400).json({ error: 'username required' });
    const info = players[target];
    if (info) {
        res.json({ placeId: info.placeId, jobId: info.jobId });
    } else {
        res.json({ placeId: null, jobId: null });
    }
});

// ------------------ تشغيل السيرفر ------------------
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
