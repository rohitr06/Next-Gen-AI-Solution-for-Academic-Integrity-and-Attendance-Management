const express = require('express');
const cors = require('cors');
const XLSX = require('xlsx');
const path = require('path');

const app = express();
const PORT = 5000;

app.use(cors());
app.use(express.json());

// Path to your Excel file
const EXCEL_FILE_PATH = path.join(__dirname, 'attendance.xlsx');

app.post('/update_attendance', (req, res) => {
  const { barcode } = req.body;
  if (!barcode) {
    return res.status(400).json({ error: 'No barcode provided' });
  }

  try {
    // Read Excel file
    const workbook = XLSX.readFile(EXCEL_FILE_PATH);
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];

    // Convert sheet to JSON array of objects
    const data = XLSX.utils.sheet_to_json(worksheet, { header: 1 }); // Array of arrays

    // Find the barcode in first column (row[0])
    let found = false;
    for (let i = 1; i < data.length; i++) { // skipping header row
      if (data[i][0] && data[i][0].toString() === barcode.toString()) {
        // Mark attendance in second column (index 1)
        data[i][1] = 'Present';
        found = true;
        break;
      }
    }

    if (!found) {
      return res.status(404).json({ error: 'Barcode not found' });
    }

    // Convert back to sheet and save
    const newWorksheet = XLSX.utils.aoa_to_sheet(data);
    workbook.Sheets[sheetName] = newWorksheet;
    XLSX.writeFile(workbook, EXCEL_FILE_PATH);

    return res.json({ message: `Attendance marked for barcode: ${barcode}` });
  } catch (error) {
    console.error('Error updating Excel:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});
