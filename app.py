from flask import Flask, render_template
from data import genres, bands

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html', genres=genres, bands=bands)

if __name__ == '__main__':
    app.run(debug=True)