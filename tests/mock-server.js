const express = require('express');
const app = express();
app.use(express.json());

app.patch('/repos/:owner/:repo', (req, res) => {
  console.log(`Mock intercepted: PATCH /repos/${req.params.owner}/${req.params.repo}`);
  console.log('Request headers:', JSON.stringify(req.headers));
  console.log('Request body:', JSON.stringify(req.body));

  // Validate request body
  const { archived } = req.body;
  if (typeof archived !== 'boolean') {
    return res.status(422).json({ message: 'Invalid archived status' });
  }

  // Simulate repository existence check
  if (req.params.owner === 'invalid-owner' || req.params.repo === 'invalid-repo') {
    return res.status(404).json({ message: 'Repository not found' });
  }

  // Simulate successful archive
  res.status(200).json({ archived });
});

app.listen(3000, () => {
  console.log('Mock server listening on http://127.0.0.1:3000...');
});
