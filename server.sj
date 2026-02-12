const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// تخزين البيانات
let players = {};        // { username: { placeId, jobId, lastPing } }
let lastCommand = {      // آخر أمر أرسله قائد
    username: null,
    message: null,
    time: 0
};

// حذف اللاعبين غير النشطين (آخر ping قبل 30 ثانية)
setInterval(() => {
    const now = Date.now();
    for (let user in players) {
        if (now - players[user].lastPing > 30000) {
            delete players[user];
        }
    }
}, 10000);

// -------------------- المسارات --------------------

// تحديث وجود اللاعب
app.post('/ping', (req, res) => {
    const { username, placeId, jobId } = req.body;
    if (username) {
        players[username] = {
            placeId,
            jobId,
            lastPing: Date.now()
        };
    }
    res.json({ success: true });
});

// جلب قائمة جميع اللاعبين المتصلين
app.get('/players', (req, res) => {
    res.json(Object.keys(players));
});

// إرسال أمر جديد
app.post('/update', (req, res) => {
    const { username, message, time } = req.body;
    if (username && message) {
        lastCommand = { username, message, time };
        res.json({ success: true });
    } else {
        res.status(400).json({ error: 'Missing data' });
    }
});

// جلب آخر أمر
app.get('/data', (req, res) => {
    res.json(lastCommand);
});

// معلومات هدف لإعادة الانضمام (اختياري، قد تحتاجه إذا أضفت زر rejoin لاحقاً)
app.get('/target_info', (req, res) => {
    const username = req.query.username;
    if (username && players[username]) {
        res.json(players[username]);
    } else {
        res.status(404).json({ error: 'User not found' });
    }
});

// الصفحة الرئيسية
app.get('/', (req, res) => {
    res.send('Wa7eed v4 Server is running');
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
