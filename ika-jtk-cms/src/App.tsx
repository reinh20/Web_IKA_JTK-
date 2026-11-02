import { RouterProvider } from 'react-router-dom'
import { router } from '@/app/router'
import { ToastContainer } from '@/components/ui/Toast'

function App() {
  return (
    <>
      <RouterProvider router={router} />
      <ToastContainer />
    </>
  )
}

export default App
