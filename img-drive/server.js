const express = require('express');
const morgan = require('morgan');
const multer = require('multer');
const upload = multer({ dest: __dirname + '/uploads/images' });
const app = express();
const PORT = 8080;

app.use(morgan('dev'));
app.use(express.json());
app.use(express.static('./client'));

// upload file. currently uploading to a directory
// replace with uploading to a DB later
app.post('/upload', upload.single('photo'), (req, res) => {
  if (req.file) {
    res.json(req.file);
  }
});

app.get('/pictures', (req, res) => {
  res.sendFile('/Users/kent/revature-p1/img-drive/uploads/images/093256e7e9dd532222ece1139a24d006');
});

// eslint-disable-next-line no-console
app.listen(PORT, () => console.log(`Server up on PORT ${PORT}`));
