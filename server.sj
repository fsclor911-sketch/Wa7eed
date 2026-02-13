const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// ========== تخزين البيانات في الذاكرة ==========
let onlinePlayers = {};      // اسم اللاعب -> {placeId, jobId, lastSeen}
let commands = {};          // اسم الهدف -> {username, message, time}

// ========== تنظيف القديم كل 30 ثانية ==========
setInterval(() => {
    const now = Date.now();
    // حذف اللاعبين غير النشطين
    for (let [name, data] of Object.entries(onlinePlayers)) {
        if (now - data.lastSeen > 30000) {
            delete onlinePlayers[name];
        }
    }
    // حذف الأوامر الأقدم من دقيقتين (اختياري)
    for (let [target, cmd] of Object.entries(commands)) {
        if (now - cmd.time * 1000 > 120000) {
            delete commands[target];
        }
    }
}, 30000);

// ========== Endpoints ==========

// 📡 Ping - تحديث حالة اللاعب
app.post('/ping', (req, res) => {
    const { username, placeId, jobId } = req.body;
    if (!username) return res.status(400).json({ error: 'Missing username' });
    onlinePlayers[username] = {
        placeId,
        jobId,
        lastSeen: Date.now()
    };
    res.json({ status: 'ok' });
});

// 📋 قائمة جميع اللاعبين النشطين
app.get('/players', (req, res) => {
    const players = Object.keys(onlinePlayers);
    res.json(players);
});

// 📤 استلام أمر من القائد
app.post('/update', (req, res) => {
    const { username, message, time } = req.body;
    if (!username || !message) return res.status(400).json({ error: 'Missing data' });

    const parts = message.split(' ');
    const cmd = parts[0];
    let target = parts[1];

    // إذا لم يحدد هدف، نعتبر الأمر عام
    if (!target) target = 'all';

    // تخزين الأمر تحت اسم الهدف
    commands[target] = {
        username,   // اسم القائد
        message,
        time
    };

    // إذا كان الأمر "tzaghba" نحتاج أن نرسل للهدف اسم القائد أيضاً
    // يتم ذلك عبر تخزين الرسالة كاملة، والضحية ستفهم من السياق
    res.json({ status: 'ok' });
});

// 📥 جلب الأمر الخاص بلاعب معين
app.get('/command', (req, res) => {
    const target = req.query.target;
    if (!target) return res.status(400).json({ error: 'Missing target' });

    // نبحث عن أمر موجه لهذا اللاعب بالضبط
    let cmd = commands[target];
    
    // أيضاً نبحث عن أمر عام 'all'
    if (!cmd && commands['all']) {
        cmd = commands['all'];
    }

    if (cmd) {
        res.json(cmd);
    } else {
        res.json({});  // لا يوجد أمر جديد
    }
});

// ℹ️ معلومات الـ placeId و jobId للاعب (اختياري، محتفظ به للتوافق)
app.get('/target_info', (req, res) => {
    const username = req.query.username;
    if (!username) return res.status(400).json({ error: 'Missing username' });
    const player = onlinePlayers[username];
    if (player) {
        res.json({ placeId: player.placeId, jobId: player.jobId });
    } else {
        res.status(404).json({ error: 'Player not found' });
    }
});

// 🏁 تشغيل الخادم
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
