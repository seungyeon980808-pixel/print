import unittest, json, gzip
from imyong_data import extract_points, select_items, load_items, load_taxonomy, stable_hash

class ImyongTests(unittest.TestCase):
    def test_total_before_subscores(self):
        self.assertEqual(extract_points('(총 4점) 1-1. (2점) 1-2. (2점)')[0],4)
        self.assertEqual(extract_points('문제 [2점]')[0],2)
        self.assertEqual(extract_points('문제 (2점)')[0],2)
        self.assertIsNone(extract_points('1-1 (2점) 1-2 (2점)')[0])
        self.assertIsNone(extract_points('배점 미표시')[0])
    def test_filters_and_evidence(self):
        data=load_items();items=data['items'];selected=select_items(items)
        self.assertEqual(len(items),2588);self.assertEqual(len(selected),1331)
        self.assertTrue(all(q['pointsEvidence'] for q in selected))
        self.assertTrue(all(q['points'] in (2,4) for q in selected))
        hits=select_items(items,['t_physics'],(2014,2026),'','전자기 유도')
        self.assertTrue(hits);self.assertTrue(all(q['subject']=='t_physics' for q in hits))
        self.assertRaises(ValueError,select_items,items,(),(2026,2020))
        self.assertRaises(ValueError,select_items,items,(),(2002,2026),'','하나 둘 셋 넷')
    def test_topics_selection_exclusion_and_reproducible_sample(self):
        data=load_items();items=data['items'];taxonomy=load_taxonomy()
        allowed={t['id'] for u in taxonomy['units'] for t in u['topics']}
        self.assertTrue(all(q['topicIds'] and set(q['topicIds'])<=allowed for q in items))
        self.assertEqual(next(q for q in items if q['id']=='t_physics_2026_A_02')['topicIds'],['t_physics.quantum.operators'])
        topics=['t_physics.quantum.operators','t_physics.quantum.applications']
        hits=select_items(items,['t_physics'],(2017,2026),topic_ids=topics,exclude_keywords='섭동',limit=12,sort_mode='random',seed='양자1')
        self.assertEqual(len(hits),12);self.assertEqual(len({q['id'] for q in hits}),12)
        self.assertTrue(all(set(q['topicIds'])&set(topics) and '섭동' not in q['text'] for q in hits))
        again=select_items(items,['t_physics'],(2017,2026),topic_ids=topics,exclude_keywords='섭동',limit=12,sort_mode='random',seed='양자1')
        self.assertEqual([q['id'] for q in hits],[q['id'] for q in again])
        self.assertTrue(all(q['paper']=='B' for q in select_items(items,paper_part='B')))
        self.assertEqual(stable_hash('hello'),0x4f9f2cab)
if __name__=='__main__':unittest.main()
