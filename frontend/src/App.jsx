import './App.css'
import heroImage from './assets/hero.png'

function App() {
  return (
    <main className="top-page">
      <img src={heroImage} alt="あいのてのイメージ画像" className="hero-image" />
      <p><br></br></p>
      <p className="catchphrase">
        言葉ですれ違ってしまう気持ちを、落ち着いて伝え合えるように。
      </p>
      <p className="description">
        あいのては、AIが対話を支援することで、感情的にならずに大切な人と話し合えるようになるサービスです。
      </p>
    </main>
  )
}

export default App