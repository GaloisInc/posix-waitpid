{-# LANGUAGE ForeignFunctionInterface #-}
{-# CFILES System/Posix/waitpid.c #-}

module System.Posix.Waitpid where

import Control.Monad
import Data.List
import Foreign
import Foreign.C
import Foreign.C.Types(CInt(..))
import System.Posix.Signals (Signal)
import System.Posix.Types (CPid(..))

foreign import ccall unsafe "SystemPosixWaitpid_waitpid" c_waitpid :: CPid -> Ptr CInt -> CInt -> IO CPid

data Flag = NoHang | IncludeUntraced | IncludeContinued deriving Show
data Status = Exited Int | Signaled Signal | Stopped Signal | Continued deriving (Show, Eq)

waitpid :: CPid -> [Flag] -> IO (Maybe (CPid, Status))
waitpid pid flags = alloca $ \status -> do
  child <- throwErrnoIfMinus1 "waitpid" $ c_waitpid pid status options
  stat <- peek status
  return $ guard (child /= 0) >> return (child, extractStatus stat)
 where
  options = foldl' (.|.) 0 (map flagValue flags)
  flagValue NoHang = 1
  flagValue IncludeUntraced = 2
  flagValue IncludeContinued = 4
  extractStatus stat | stat < 0x10000 = Exited (fromIntegral stat)
                     | stat < 0x20000 = Signaled (stat - 0x10000)
                     | stat < 0x30000 = Stopped (stat - 0x20000)
                     | stat == 0x30000 = Continued
                     | otherwise = error $ "waitpid: unexpected status " ++ show stat
