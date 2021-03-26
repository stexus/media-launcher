from ..helpers.anilist import Anilist
import unittest

api = Anilist()

class TestAnilistAPI(unittest.TestCase):
    viewer = 660744
    def test_get_viewer(self):
        self.assertEqual(api._get_viewer(), self.viewer)
    def test_get_progress_not_in_list(self):
        horimiya = 124080
        self.assertEqual(api._get_progress(self.viewer, horimiya), 0)
    def test_get_progress_in_list(self):
        aot = 16498
        self.assertEqual(api._get_progress(self.viewer, aot), 25)
    def test_is_complete(self):
        aot = 16498
        self.assertEqual(api._is_complete(aot, 25), True)
if __name__ == '__main__':
    unittest.main()
