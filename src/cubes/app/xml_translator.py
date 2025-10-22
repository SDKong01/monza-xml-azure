import os
import xml.etree.ElementTree as ET
from fastapi import HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional
from pathlib import Path
from src.cubes.domain.entities import Cube


class CubeXMLTranslator:
    def __init__(self, cube: Cube):
        self.cube = cube

    DEFAULT_XML = """<?xml version="1.0" encoding="utf-8"?>
<Schema name="default">
</Schema>
"""

    def _parse_existing_xml(self):
        """Parse the XML file and return the root element"""
        try:
            xml_string = self.cube.xml or self.DEFAULT_XML
            tree = ET.ElementTree(ET.fromstring(xml_string))
            return tree, tree.getroot()
        except ET.ParseError as e:
            raise HTTPException(
                status_code=500, detail=f"Error parsing XML file: {str(e)}"
            )

    def _format_xml(self, root):
        """Format XML with proper indentation and line breaks"""

        def indent(elem, level=0):
            i = "\n" + level * "  "
            if len(elem):
                if not elem.text or not elem.text.strip():
                    elem.text = i + "  "
                if not elem.tail or not elem.tail.strip():
                    elem.tail = i
                for subelem in elem:
                    indent(subelem, level + 1)
                if not elem.tail or not elem.tail.strip():
                    elem.tail = i
            else:
                if level and (not elem.tail or not elem.tail.strip()):
                    elem.tail = i

        indent(root)

    def create_cube(self):
        """Create a new cube in the XML file"""
        tree, root = self._parse_existing_xml()

        schema = root.find('.//Schema')
        if schema is None:
            # If no Schema found, assume root is the Schema
            schema = root

        # Find all existing cubes to determine insertion position
        existing_cubes = schema.findall('.//Cube')

        # Create the new cube element
        cube_elem = ET.SubElement(schema, "Cube")
        cube_elem.set("name", self.cube.name)

        # Create the table element
        table_elem = ET.SubElement(cube_elem, "Table")
        table_elem.set("name", self.cube.table)

        # Create dimensions
        for dim in self.cube.dimensions:
            dimension_elem = ET.SubElement(cube_elem, "Dimension")
            dimension_elem.set("name", dim.name)

            # Create hierarchies for the dimension
            for hierarchy in dim.hierarchies:
                hierarchy_elem = ET.SubElement(dimension_elem, "Hierarchy")

                # Set hierarchy attributes
                if hierarchy.name:
                    hierarchy_elem.set("name", hierarchy.name)
                hierarchy_elem.set("hasAll", str(hierarchy.hasAll).lower())
                if hierarchy.allMemberName:
                    hierarchy_elem.set("allMemberName", hierarchy.allMemberName)

                # Create levels for the hierarchy
                for level in hierarchy.levels:
                    level_elem = ET.SubElement(hierarchy_elem, "Level")
                    level_elem.set("name", level.name)
                    level_elem.set("column", level.column)
                    level_elem.set("type", level.type)
                    if level.uniqueMembers is not None:
                        level_elem.set(
                            "uniqueMembers", str(level.uniqueMembers).lower()
                        )

        # Create measures
        for measure in self.cube.measures:
            measure_elem = ET.SubElement(cube_elem, "Measure")
            measure_elem.set("name", measure.name)
            measure_elem.set("column", measure.column)
            measure_elem.set("aggregator", measure.aggregator)
            if measure.formatString:
                measure_elem.set("formatString", measure.formatString)

        # Move the new cube to the end (after all existing cubes)
        if existing_cubes:
            # Remove the cube from its current position
            schema.remove(cube_elem)
            # Insert it at the end (after all existing cubes)
            schema.append(cube_elem)

        root_str = ET.tostring(root, encoding="utf-8").decode("utf-8")
        return root_str

    def generate_xml(self) -> str:
        pass
