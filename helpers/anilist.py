#!/usr/bin/env python3

import sys
from pathlib import Path
import requests
#todo:
#set timer for search so search only happens when stop typing done
#look through rofiftw to see how rofi blocks is used done
#look through rofi blocks examples done
#set up oauth custom url and queries in this python script (search, mutation)
#(done in lua) loop through anilist entries in json and determine which series is currently being updated based on episode number
#change to symlink
absolute_dir = Path(__file__).absolute().parent.parent
sys.path.insert(0, absolute_dir.name)
from helpers.secrets import access_token
class Anilist:
    def __init__(self):
        self.url = 'https://graphql.anilist.co'
        self.curr_search = {}
        self.token = access_token
    def create_query(self, queryDict) -> str:
        return ''

    def search(self, input) -> list[str]:
        if not input or len(input) == 1: return []
        query = '''
            query($search: String) {
                Page(page: 1, perPage: 7)  {
                    media(search: $search, type: ANIME) {
                        id
                        title {
                            romaji
                        }
                    } 
                }
            }
        '''
        variables = {
            'search': input
        }
        response = requests.post(self.url, json={'query': query, 'variables': variables})
        titles = self._get_titles(response.json()['data']['Page']['media'])
        return titles

    def _get_viewer(self) -> int:
        response = requests.post(self.url, json={'query': '{Viewer {id}}'}, headers={'Authorization': f'Bearer {access_token}'})
        return response.json()['data']['Viewer']['id']

    def _get_titles(self, media) -> list[str]:
        self.curr_search = {}
        titles = []
        for entry in media:
            title = entry['title']['romaji']
            #for sending to rofiblocks
            titles.append(title)
            self.curr_search[title] = entry['id']
        return titles

    def _get_list_id(self, mediaId) -> int:
        return 0
    
    def _get_progress(self, viewer, mediaId) -> int:
        query = '''
            query($userId: Int, $mediaId: Int) {
                MediaList(userId: $userId, mediaId: $mediaId, type: ANIME) {
                    progress
                    }
                }
        '''
        progress_response = requests.post(self.url, json={'query': query, 'variables': {'userId': viewer, 'mediaId': mediaId}})
        viewer_progress = progress_response.json()['data']['MediaList']['progress']
        return viewer_progress

    def _is_complete(self, mediaId, new_progress) -> bool:
        query = '''
            query($id: Int) {
                Media(id: $id, type: ANIME) {
                    episodes
                    }
                }
        '''
        #id here is for media, not for list
        response = requests.post(self.url, json={'query': query, 'variables': {'id': mediaId}})
        total_ep = response.json()['data']['Media']['episodes']
        return total_ep <= new_progress 

    def update_entry(self, id):
        auth_header = {'Authorization': f'Bearer {self.token}'}
        query = '''
                mutation ($mediaId: Int, $status: MediaListStatus, $progress: Int) {
                    SaveMediaListEntry (mediaId: $mediaId, status: $status, progress: $progress) {
                            id
                            progress
                    }
                }
        '''
        viewer = self._get_viewer()
        new_progress = self._get_progress(viewer, id) + 1
        variables = {
            'mediaId': id,
            'status': 'COMPLETE' if self._is_complete(id, new_progress) else 'CURRENT',
            'progress': new_progress
        }
        response = requests.post(self.url, headers=auth_header, json={'query': query, 'variables': variables})
        return response.json()

