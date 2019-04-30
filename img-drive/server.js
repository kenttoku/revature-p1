const express = require('express');
const morgan = require('morgan');
const multer = require('multer');
const upload = multer({ dest: __dirname + '/uploads/images' });
const app = express();
const PORT = 8080;

app.use(morgan('dev'));
app.use(express.json());
app.use(express.static('./client'));

app.post('/upload', upload.single('photo'), (req, res) => {
  if (req.file) {
    res.json(req.file);
  }
});

// eslint-disable-next-line no-console
app.listen(PORT, () => console.log(`Server up on PORT ${PORT}`));
